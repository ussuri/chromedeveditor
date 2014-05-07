// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark_widgets;

import 'dart:html';

import 'package:polymer/polymer.dart';

const bool IS_DART2JS = identical(1, 1.0);

// NOTE: This SparkWidget element is not intended to use directly.
@CustomTag('spark-widget')
class SparkWidget extends PolymerElement {
  SparkWidget.created() : super.created();

  String joinClasses(List<String> cls) => cls.join(" ");

  Element getShadowDomElement(String selectors) =>
      shadowRoot.querySelector(selectors);

  /**
   * Override the standard behavior of the built-in focus():
   * look for a sub-element with an `focused` attribute, first in the
   * light DOM and then in shadow DOM, and if found, focus it; otherwise,
   * focus ourselves.
   *
   * Note that the found sub-element may itself be a
   * SparkWidget, and as such trigger a recursive autofocusing process.
   */
  @override
  void focus() {
    super.focus();
    _applyAutofocus(true);
  }

  /**
   * Override the standard behavior of the built-in blur():
   * reverse the effect of a previous call to [focus].
   */
  @override
  void blur() {
    super.blur();
    _applyAutofocus(false);
  }

  /**
   * Perform the actual autofocusing used in [focus] and [blur].
   */
  void _applyAutofocus(bool isFocused) {
    //
    ElementList elts = this.querySelectorAll('[focused]');
    if (elts.isEmpty) {
      elts = shadowRoot.querySelectorAll('[focused]');
    }
    if (elts.isNotEmpty) {
      // At most one element is expected to have an `focused` attribute.
      // Use [first] vs [single] to be more lax to errors in production.
      assert(elts.length == 1);
      isFocused ? elts.first.focus() : elts.first.blur();
    }
  }

  /**
   * Certain kinds of elements, e.g. <div>, by default do not accept keyboard
   * events. Assinging tabIndex to them makes them keyboard-focusable, and
   * therefore accepting keyboard events.
   */
  void enableKeyboardEvents() {
    if (tabIndex == null) {
      tabIndex = 0;
    }
  }

  /**
   * Put an opaque veil over the element.
   */
  void veil() {
    classes..remove('unveiled')..toggle('veiled', true);
  }

  /**
   * Undo the result of [veil].
   */
  void unveil() {
    classes..remove('veiled')..toggle('unveiled', true);
  }

  /**
   * Prevent FOUC (Flash Of Unstyled Content).
   */
  void preventFlashOfUnstyledContent({Function method,
                                      Duration delay}) {
    // TODO(ussuri): We use a temporary crude way here. Polymer's advertised
    // machanisms (via :resolved pseudo class as well as older .polymer-veiled
    // class) have failed to work so far, although :unresolved reportedly
    // functions in Chrome 34. Revisit.
    veil();

    if (method != null) {
      method();
    }

    if (delay != null) {
      asyncTimer(unveil, delay);
    } else {
      unveil();
    }
  }

  /**
   * Find a <content> element using a CSS selector and expand it, and any
   * recursively nested <content> elements distributed from light DOM as a result
   * of multi-level element embedding, with their children.
   */
  Iterable<Node> getExpandedDistributedNodes(String contentSelector) {
    final ContentElement content = shadowRoot.querySelector(contentSelector);
    return inlineNestedContentNodes(content);
  }

  /**
   * Inline a given <content> element, and any recursively nested <content> elements
   * distributed from light DOM as a result of multi-level element embedding, with
   * their children.
   */
  static Iterable<Node> inlineNestedContentNodes(ContentElement content) {
    final List<Node> dn = content.getDistributedNodes();
    final Iterable<Node> fdn = dn.where(
        (Node e) => (e is Element) && e.localName != "template");
    final Iterable<Node> edn = fdn.expand(
        (Node e) => e is ContentElement ?
            inlineNestedContentNodes(e) : [e]);
    return edn;
  }
}
