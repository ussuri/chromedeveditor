// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui_access;

import 'dart:async';
import 'dart:html';

import 'package:spark_widgets/spark_dialog/spark_dialog.dart';
import 'package:spark_widgets/spark_dialog_button/spark_dialog_button.dart';
import 'package:spark_widgets/spark_menu_button/spark_menu_button.dart';
import 'package:spark_widgets/spark_menu_item/spark_menu_item.dart';
import 'package:spark_widgets/spark_button/spark_button.dart';
import 'package:spark_widgets/spark_modal/spark_modal.dart';
import 'package:spark_widgets/spark_overlay/spark_overlay.dart';
import 'package:spark_widgets/common/spark_widget.dart';

import '../../spark_polymer_ui.dart';

class SparkUIAccess {
  static SparkUIAccess _instance;

  OkCancelDialogAccess okCancelDialog = new OkCancelDialogAccess();
  AboutDialogAccess aboutDialog = new AboutDialogAccess();
  NewProjectDialogAccess newProjectDialog = new NewProjectDialogAccess();
  DialogAccess gitCloneDialog = new DialogAccess("gitCloneDialog");

  MenuItemAccess newProjectMenu;
  MenuItemAccess gitCloneMenu;
  MenuItemAccess aboutMenu;

  SparkMenuButton get menu => getUIElement("#mainMenu");
  Stream get onMenuTransitioned => _menuOverlay.on['transition-complete'];

  SparkPolymerUI get _ui => document.querySelector('#topUi');
  SparkButton get _sparkMenuButton => getUIElement("#mainMenu > spark-button");
  SparkOverlay get _menuOverlay => menu.getShadowDomElement("#overlay");

  static SparkUIAccess get instance {
    if (_instance == null) _instance = new SparkUIAccess._internal();
    return _instance;
  }

  SparkUIAccess._internal() {
    newProjectMenu = new MenuItemAccess("project-new", newProjectDialog);
    gitCloneMenu = new MenuItemAccess("git-clone", gitCloneDialog);
    aboutMenu = new MenuItemAccess("help-about", aboutDialog);
  }

  Element getUIElement(String selectors) => _ui.getShadowDomElement(selectors);

  void _sendMouseEvent(Element element, String eventType) {
    Rectangle<int> bounds = element.getBoundingClientRect();
    element.dispatchEvent(new MouseEvent(eventType,
        clientX: bounds.left.toInt() + bounds.width ~/ 2,
        clientY: bounds.top.toInt() + bounds.height ~/ 2));
  }

  void _sendKeyEvent(Element element, String eventType, int keyCode) {
    Rectangle<int> bounds = element.getBoundingClientRect();
    element.dispatchEvent(new KeyEvent(eventType, keyCode: keyCode));
  }

  Future selectSparkMenu() {
    Future transitionFuture = onMenuTransitioned.first;
    _sparkMenuButton.click();
    return transitionFuture;
  }

  void clickElement(Element element) {
    _sendMouseEvent(element, "mouseover");
    _sendMouseEvent(element, "click");
  }

  // TODO(ericarnold): This doesn't work
  void sendKey(Element element, int keyCode) {
    var streamDown = KeyEvent.keyDownEvent.forTarget(document.body);
    var streamPress = KeyEvent.keyPressEvent.forTarget(document.body);
    var streamUp = KeyEvent.keyUpEvent.forTarget(document.body);

    // TODO(ericarnold): Add keydown for modifiers for this character
    streamDown.add(new KeyEvent('keydown', keyCode: keyCode));
    streamPress.add(new KeyEvent('keypress', keyCode: keyCode));
    streamUp.add(new KeyEvent('keyup', keyCode: keyCode));
    // TODO(ericarnold): Add keyup for modifiers for this character
  }

  Future sendString(InputElement input, String text, [bool useKeys]) {
    input.focus();
    if (!useKeys) {
      input.dispatchEvent(new TextEvent('textInput', data: text));
    } else {
      text.codeUnits.forEach((int keyCode) => sendKey(input, keyCode));
    }
    return new Future.value();
  }
}

class MenuItemAccess {
  final String _menuItemId;
  DialogAccess _dialogAccess = null;

  DialogAccess get dialogAccess => _dialogAccess;

  SparkUIAccess get _sparkAccess => SparkUIAccess.instance;

  SparkMenuItem get _menuItem => _getMenuItem(_menuItemId);

  MenuItemAccess(this._menuItemId, [DialogAccess linkedDialogAccess]) {
    _dialogAccess = (linkedDialogAccess == null) ? null : linkedDialogAccess;
  }

  void select() => _sparkAccess.clickElement(_menuItem);

  SparkMenuItem _getMenuItem(String id) =>
      _sparkAccess.menu.querySelector("spark-menu-item[action-id=$id]");
}

class DialogAccess {
  final String id;

  SparkModal get modalElement => _dialog.getShadowDomElement("#modal");
  bool get opened => modalElement.opened;
  SparkWidget get closingXButton => _getBySelector("#closingX");

  bool get fullyVisible {
    Rectangle<int> bounds = modalElement.getBoundingClientRect();
    var elementFromPoint = _sparkAccess._ui.shadowRoot.elementFromPoint(
        bounds.left.toInt() + bounds.width ~/ 2,
        bounds.top.toInt() + bounds.height ~/ 2);
    SparkDialog dialog = _dialog;
    return elementFromPoint == _dialog || _dialog.contains(elementFromPoint);
  }

  Stream get onTransitionComplete => modalElement.on['transition-complete'];

  SparkUIAccess get _sparkAccess => SparkUIAccess.instance;
  SparkDialog get _dialog => _sparkAccess.getUIElement("#$id");
  List<SparkDialogButton> get _dialogButtons =>
      _dialog.querySelectorAll("spark-dialog-button");

  DialogAccess(this.id);

  void clickButton(SparkWidget button) => _sparkAccess.clickElement(button);
//  void clickButtonWithTitle(String title) => clickButton(_getButtonByTitle(title));
//  void clickButtonWithSelector(String query) =>
//      clickButton(_getButtonBySelector(query));

  SparkWidget _getButtonByTitle(String title) =>
      _dialogButtons.firstWhere((b) => b.text.toLowerCase() == title.toLowerCase());

  Element _getBySelector(String query) {
    Element button = _dialog.querySelector(query);

    if (button == null) button = _dialog.getShadowDomElement(query);

    if (button == null) throw "Could not find button with selector $query";

    return button;
  }
}

class OkCancelDialogAccess extends DialogAccess {
  SparkDialogButton get okButton => _getButtonByTitle("ok");
  SparkDialogButton get cancelButton => _getButtonByTitle("cancel");

  OkCancelDialogAccess() : super("okCancelDialog");

  void clickOkButton() => _sparkAccess.clickElement(okButton);
  void clickCancelButton() => _sparkAccess.clickElement(cancelButton);
}

class AboutDialogAccess extends DialogAccess {
  SparkDialogButton get doneButton => _getButtonByTitle("done");

  AboutDialogAccess() : super("aboutDialog");

  void clickDoneButton() => _sparkAccess.clickElement(doneButton);
}

class NewProjectDialogAccess extends DialogAccess {
  SparkDialogButton get createButton => _getButtonByTitle("Create");
  SparkDialogButton get cancelButton => _getButtonByTitle("Cancel");
  Element get nameField => _getBySelector("#name");

  NewProjectDialogAccess() : super("newProjectDialog");

  void clickCreateButton() => _sparkAccess.clickElement(createButton);

  void setNameField(String text) {
    var nameField = this.nameField;
    _sparkAccess.sendString(nameField, text, false);
  }
}
