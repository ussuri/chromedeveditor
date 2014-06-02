// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark_widgets.menu_button;

import 'dart:async';
import 'dart:html';

import 'package:polymer/polymer.dart';

import '../common/spark_widget.dart';
import '../spark_button/spark_button.dart';
import '../spark_menu_box/spark_menu_box.dart';

@CustomTag("spark-menu-button")
class SparkMenuButton extends SparkWidget {
  @published dynamic selected;
  @published String valueAttr = '';
  @published bool opened = false;
  @published String arrow = 'none';

  SparkButton _button;
  SparkMenuBox _menu;

  final List<bool> _toggleQueue = [];
  Timer _toggleTimer;

  SparkMenuButton.created(): super.created();

  @override
  void enteredView() {
    super.enteredView();

    _menu = $['menu'];

    final ContentElement buttonCont = $['button'];
    assert(buttonCont.getDistributedNodes().isNotEmpty);
    _button = buttonCont.getDistributedNodes().first;
    _button
        ..onClick.listen(clickHandler)
        ..onFocus.listen(focusHandler)
        ..onBlur.listen(blurHandler)
        ..onKeyDown.listen(keyDownHandler);
  }

  /**
   * Schedule a toggle of the opened state of the dropdown. Don't toggle right
   * away, as there can be multiple events coming in a quick succession
   * following a user gesture (e.g. a click on the button can trigger
   * blur->click->focus, and possibly on-closed as well). Instead,
   * aggregate arriving events for a short while after the first one,
   * then compute their net effect and commit.
   */
  void _toggle(bool inOpened) {
    _toggleQueue.add(inOpened);
    if (_toggleTimer == null) {
      _toggleTimer = new Timer(
          const Duration(milliseconds: 200), _completeToggle);
    }
  }

  /**
   * Complete the toggling process, see [_toggle].
   */
  void _completeToggle() {
    // Most likely, all aggregated events for a single gesture will have the
    // same value (either 'close' or 'open'), but we don't count on that and
    // formally && all the values just in case.
    final bool newOpened = _toggleQueue.reduce((a, b) => a && b);
    if (newOpened != opened) {
      opened = newOpened;
      // TODO(ussuri): A temporary plug to make #menu and #button see
      // changes in 'opened'. Data binding via {{opened}} in the HTML isn't
      // detected. deliverChanges() fixes #overlay, but not #button.
      _menu..opened = newOpened..deliverChanges();
      _button..active = newOpened..deliverChanges();
      if (newOpened) {
        // Enforce focused state so the button can accept keyboard events.
        focus();
        _menu.resetState();
      }
    }
    _toggleQueue.clear();
    _toggleTimer.cancel();
    _toggleTimer = null;
  }

  void clickHandler(Event e) => _toggle(!opened);

  void focusHandler(Event e) => _toggle(true);

  void blurHandler(Event e) => _toggle(false);

  /**
   * Handle the on-opened event from the dropdown. It will be fired e.g. when
   * mouse is clicked outside the dropdown (with autoClosedDisabled == false).
   */
  void menuOverlayOpenedHandler(CustomEvent e) {
    // Autoclosing is the only event we're interested in.
    if (e.detail == false) {
      _toggle(false);
    }
  }

  void menuActivateHandler(CustomEvent e, var details) {
    if (details['isSelected']) {
      _toggle(false);
    }
  }

  void keyDownHandler(KeyboardEvent e) {
    bool stopPropagation = true;

    if (_menu.maybeHandleKeyStroke(e.keyCode)) {
      e.preventDefault();
    }

    switch (e.keyCode) {
      case KeyCode.UP:
      case KeyCode.DOWN:
      case KeyCode.PAGE_UP:
      case KeyCode.PAGE_DOWN:
      case KeyCode.ENTER:
        if (!opened) opened = true;
        break;
      case KeyCode.ESC:
        this.blur();
        break;
      default:
        stopPropagation = false;
        break;
    }

    if (stopPropagation) {
      e.stopPropagation();
    }
  }
}
