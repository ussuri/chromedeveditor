// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.exception;

import 'git/exception.dart';

/**
 * A wrapper class for all errors thrown inside spark. Each error is represented
 * by a unique [errorCode] pre-defined by SparkErrorConstants class.
 */
class SparkException implements Exception {
  /// The error message.
  final String message;
  /// Represents the unique string for each error type.
  final String errorCode;
  /// Indicates if the error is not necessary to be handled and can be ignored.
  bool canIgnore = false;

  SparkException(this.message, [this.errorCode, this.canIgnore]);

  static SparkException fromException(Exception e) {
    if (e is SparkException) {
      return e;
    } else if (e is GitException) {
      return _fromGitException(e);
    } else if (e != null) {
      return new SparkException(e.toString());
    } else {
      return new SparkException("Unknown error.");
    }
  }

  static SparkException _fromGitException(GitException e) {
    if (e.errorCode == GitErrorConstants.GIT_AUTH_REQUIRED) {
      return new SparkException(e.toString(),
            SparkErrorConstants.AUTH_REQUIRED);
    } else if (e.errorCode == GitErrorConstants.GIT_HTTP_FORBIDDEN_ERROR) {
      return new SparkException(e.toString(),
             SparkErrorConstants.GIT_HTTP_FORBIDDEN_ERROR);
    } else if (e.errorCode == GitErrorConstants.GIT_CLONE_CANCEL) {
      return new SparkException(e.toString(),
        SparkErrorConstants.GIT_CLONE_CANCEL, true);
    } else if (e.errorCode
        == GitErrorConstants.GIT_SUBMODULES_NOT_YET_SUPPORTED)  {
      return new SparkException(e.toString(),
        SparkErrorConstants.GIT_SUBMODULES_NOT_YET_SUPPORTED);
    } else if (e.errorCode == SparkErrorConstants.GIT_PUSH_NON_FAST_FORWARD) {
      return new SparkException(SparkErrorMessages.GIT_PUSH_NON_FAST_FORWARD_MSG,
        SparkErrorConstants.GIT_PUSH_NON_FAST_FORWARD);
    } else {
      return new SparkException(e.toString());
    }
  }

  String toString() => errorCode == null ?
      "SparkException: $message" : "SparkException($errorCode): $message";
}

/**
 * Defines all error types in spark as string. Each error string represents a
 * unique [SparkException].
 */
class SparkErrorConstants {
  static final String BRANCH_NOT_FOUND = "branch_not_found";
  static final String GIT_CLONE_DIR_IN_USE = "git.clone_dir_in_use";
  static final String AUTH_REQUIRED = "auth.required";
  static final String GIT_CLONE_CANCEL = "git.clone_cancel";
  static final String GIT_SUBMODULES_NOT_YET_SUPPORTED
      = "git.submodules_not_yet_supported";
  static final String GIT_HTTP_FORBIDDEN_ERROR = "git.http_forbidden_error";
  static final String GIT_PUSH_NON_FAST_FORWARD
      = "git.push_non_fast_forward";
}

class SparkErrorMessages {
  static final String GIT_PUSH_NON_FAST_FORWARD_MSG
      = 'Non fast-forward push is not yet supported.';
}
