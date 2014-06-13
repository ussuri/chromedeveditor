// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// TODO(ussuri): Add tests.

/**
 * Bower services.
 */

library spark.package_mgmt.bower;

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:logging/logging.dart';

import 'package_manager.dart';
import 'bower_fetcher.dart';
import 'bower_properties.dart';
import '../jobs.dart';
import '../workspace.dart';

Logger _logger = new Logger('spark.bower');

class BowerManager extends PackageManager {
  BowerManager(Workspace workspace) : super(workspace);

  //
  // PackageManager abstract interface:
  //

  PackageServiceProperties get properties => bowerProperties;

  PackageBuilder getBuilder() => new _BowerBuilder();

  PackageResolver getResolverFor(Project project) =>
      new _BowerResolver._(project);

  Future installPackages(Folder container) =>
      _installOrUpgradePackages(container.project, FetchMode.INSTALL);

  Future upgradePackages(Folder container) =>
      _installOrUpgradePackages(container.project, FetchMode.UPGRADE);

  // TODO(keertip): implement for bower
  Future<dynamic> arePackagesInstalled(Folder container) => new Future.value(true);

  //
  // - end PackageManager abstract interface.
  //

  Future _installOrUpgradePackages(Folder container, FetchMode mode) {
    final File specFile = container.getChild(properties.packageSpecFileName);

    // The client is expected to call us only when the project has bower.json.
    if (specFile == null) {
      throw new StateError(
          '${properties.packageSpecFileName} not found under ${container.name}');
    }

    return container.getOrCreateFolder(properties.packagesDirName, true)
        .then((Folder packagesDir) {
      final fetcher = new BowerFetcher(
          packagesDir.entry, properties.packageSpecFileName);

      return fetcher.fetchDependencies(specFile.entry, mode).catchError((e) {
        _logger.severe('Error getting Bower packages', e);
        return new Future.error(e);
      }).then((_) {
        return container.refresh();
      });
    });
  }
}

/**
 * A package resolver for Bower.
 */
class _BowerResolver extends PackageResolver {
  final Project project;

  _BowerResolver._(this.project);

  //
  // PackageResolver virtual interface:
  //

  PackageServiceProperties get properties => bowerProperties;

  File resolveRefToFile(String url) {
    if (url.startsWith('/')) url = url.substring(1);
    if (url.isEmpty) return null;

    Folder folder = project.getChild(bowerProperties.packagesDirName);
    if (folder == null) return null;

    return folder.getChildPath(url);
  }

  // Not used by anybody, but could return something like
  // `/bower_components/foo/bar.js`.
  String getReferenceFor(File file) => null;
}

/**
 * A [Builder] implementation which watches for changes to `bower.json` files
 * and updates the project Bower metadata.
 */
class _BowerBuilder extends PackageBuilder {
  _BowerBuilder();

  //
  // PackageBuilder virtual interface:
  //

  PackageServiceProperties get properties => bowerProperties;

  Future build(ResourceChangeEvent event, ProgressMonitor monitor) {
    List futures = [];

    for (ChangeDelta delta in filterPackageChanges(event.changes)) {
      Resource r = delta.resource;

      if (r.isDerived()) continue;

      if (r.name == properties.packageSpecFileName && r.parent is Project) {
        futures.add(_handlePackageSpecChange(delta));
      }
    }

    return Future.wait(futures);
  }

  //
  // - end PackageBuilder virtual interface.
  //

  Future _handlePackageSpecChange(ChangeDelta delta) {
    File file = delta.resource;

    if (delta.isDelete) {
      properties.setSelfReference(file.project, null);
      return new Future.value();
    } else {
      return file.getContents().then((String spec) {
        file.clearMarkers(properties.packageServiceName);

        try {
          properties.setSelfReference(
              file.project, _parsePackageNameFromSpec(spec));
        } on Exception catch (e) {
          file.createMarker(
              properties.packageServiceName, Marker.SEVERITY_ERROR, '${e}', 1);
        }
      });
    }
  }

  String _parsePackageNameFromSpec(String spec) {
    // TODO(ussuri): Similar code is now in 3 places in package_mgmt.
    // Generalize package spec parsing as a PackageServiceProperties API.
    Map<String, dynamic> specMap = JSON.decode(spec);
    return specMap == null ? null : specMap['name'];
  }
}
