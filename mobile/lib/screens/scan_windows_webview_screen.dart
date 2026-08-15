import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart';

class ScanWindowsWebViewScreen extends StatefulWidget {
  const ScanWindowsWebViewScreen({
    super.key,
    required this.sourceName,
    required this.sourceUrl,
    required this.queryKind,
    required this.profile,
  });

  final String sourceName;
  final String sourceUrl;
  final String queryKind;
  final Map<String, dynamic> profile;

  @override
  State<ScanWindowsWebViewScreen> createState() =>
      _ScanWindowsWebViewScreenState();
}

class _ScanWindowsWebViewScreenState extends State<ScanWindowsWebViewScreen> {
  final WebviewController controller = WebviewController();

  StreamSubscription<LoadingState>? loadingSubscription;

  bool isReady = false;
  bool isAutofilling = false;
  String? errorMessage;

  String get normalizedQueryKind => widget.queryKind.trim().toLowerCase();

  String get firstName => widget.profile['first_name']?.toString().trim() ?? '';

  String get lastName => widget.profile['last_name']?.toString().trim() ?? '';

  String get fullName {
    return [firstName, lastName].where((value) => value.isNotEmpty).join(' ');
  }

  List<dynamic> get emails =>
      widget.profile['email_addresses'] as List<dynamic>? ?? [];

  List<dynamic> get phones =>
      widget.profile['phone_numbers'] as List<dynamic>? ?? [];

  Map<String, dynamic> get address {
    final raw = widget.profile['current_address'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  String get email => emails.isEmpty ? '' : emails.first.toString();

  String get phone => phones.isEmpty ? '' : phones.first.toString();

  String get street => address['street']?.toString() ?? '';

  String get city => address['city']?.toString() ?? '';

  String get state => address['state']?.toString() ?? '';

  String get postalCode => address['postal_code']?.toString() ?? '';

  String get fullAddress {
    return [
      street,
      city,
      state,
      postalCode,
    ].where((value) => value.trim().isNotEmpty).join(', ');
  }

  String get location {
    return [
      city,
      state,
      postalCode,
    ].where((value) => value.trim().isNotEmpty).join(', ');
  }

  bool get isTruePeopleSearch {
    final name = widget.sourceName.toLowerCase();

    final url = widget.sourceUrl.toLowerCase();

    return name.contains('truepeoplesearch') ||
        name.contains('true people search') ||
        url.contains('truepeoplesearch.com');
  }

  @override
  void initState() {
    super.initState();
    initializeWebView();
  }

  Future<void> initializeWebView() async {
    try {
      await controller.initialize();

      loadingSubscription = controller.loadingState.listen((state) {
        debugPrint('WINDOWS WEBVIEW STATE: $state');

        if (state == LoadingState.navigationCompleted) {
          Future<void>.delayed(
            const Duration(milliseconds: 800),
            attemptAutofill,
          );
        }
      });

      controller.url.listen((url) {
        debugPrint('WINDOWS WEBVIEW URL: $url');
      });

      controller.onLoadError.listen((error) {
        debugPrint('WINDOWS WEBVIEW LOAD ERROR: $error');
      });

      controller.onFocusChanged.listen((focused) {
        debugPrint('WINDOWS WEBVIEW FOCUS: $focused');
      });

      if (!mounted) {
        return;
      }

      setState(() {
        isReady = true;
      });

      await controller.loadUrl(widget.sourceUrl);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  Future<void> attemptAutofill() async {
    if (isAutofilling) {
      return;
    }

    isAutofilling = true;

    try {
      if (isTruePeopleSearch) {
        await fillTruePeopleSearch();
      }
    } catch (error) {
      debugPrint('WINDOWS AUTOFILL ERROR: $error');
    } finally {
      isAutofilling = false;
    }
  }

  Future<void> fillTruePeopleSearch() async {
    final script =
        '''
(function() {
  const KIND =
    '${_escapeJs(normalizedQueryKind)}';

  const DATA = {
    fullName: '${_escapeJs(fullName)}',
    phone: '${_escapeJs(phone)}',
    email: '${_escapeJs(email)}',
    city: '${_escapeJs(city)}',
    state: '${_escapeJs(state)}',
    zip: '${_escapeJs(postalCode)}',
    location: '${_escapeJs(location)}',
    address: '${_escapeJs(fullAddress)}'
  };

  function norm(value) {
    return (value || '')
      .toString()
      .replace(/\\\\s+/g, ' ')
      .trim()
      .toLowerCase();
  }

  function visible(el) {
    if (!el) {
      return false;
    }

    const style =
      window.getComputedStyle(el);

    const rect =
      el.getBoundingClientRect();

    return (
      style.display !== 'none' &&
      style.visibility !== 'hidden' &&
      style.opacity !== '0' &&
      rect.width > 0 &&
      rect.height > 0
    );
  }

  function inputs() {
    return Array.from(
      document.querySelectorAll(
        'input:not([type="hidden"]), textarea'
      )
    ).filter(
      function(el) {
        return (
          visible(el) &&
          !el.disabled &&
          !el.readOnly
        );
      }
    );
  }

  function describe(el) {
    return norm([
      el.id,
      el.name,
      el.type,
      el.placeholder,
      el.getAttribute('aria-label'),
      el.getAttribute('autocomplete'),
      el.getAttribute('title')
    ].filter(Boolean).join(' '));
  }

  function setValue(el, value) {
    if (!el || !value) {
      return false;
    }

    try {
      el.focus();

      const prototype =
        Object.getPrototypeOf(el);

      const descriptor =
        Object.getOwnPropertyDescriptor(
          prototype,
          'value'
        );

      if (
        descriptor &&
        descriptor.set
      ) {
        descriptor.set.call(
          el,
          value
        );
      } else {
        el.value = value;
      }

      el.dispatchEvent(
        new Event(
          'input',
          { bubbles: true }
        )
      );

      el.dispatchEvent(
        new Event(
          'change',
          { bubbles: true }
        )
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  function findInput(words) {
    const list =
      inputs();

    for (
      let i = 0;
      i < list.length;
      i++
    ) {
      const text =
        describe(list[i]);

      for (
        let j = 0;
        j < words.length;
        j++
      ) {
        if (
          text.includes(
            norm(words[j])
          )
        ) {
          return list[i];
        }
      }
    }

    return null;
  }

  function firstInput() {
    const list =
      inputs();

    return list.length > 0
      ? list[0]
      : null;
  }

  function secondInput() {
    const list =
      inputs();

    return list.length > 1
      ? list[1]
      : null;
  }

  function textOf(el) {
    return norm(
      el.innerText ||
      el.textContent ||
      el.getAttribute(
        'aria-label'
      )
    );
  }

  function clickTab(label) {
    const wanted =
      norm(label);

    const elements =
      Array.from(
        document.querySelectorAll(
          'button, a, [role="button"], [role="tab"], div, span'
        )
      );

    for (
      let i = 0;
      i < elements.length;
      i++
    ) {
      const el =
        elements[i];

      if (
        visible(el) &&
        textOf(el) === wanted
      ) {
        try {
          el.click();
          return true;
        } catch (_) {}
      }
    }

    return false;
  }

  function fillPhone() {
    return setValue(
      findInput([
        'phone',
        'telephone',
        'mobile',
        'tel'
      ]) ||
      firstInput(),
      DATA.phone
    );
  }

  function fillEmail() {
    return setValue(
      findInput([
        'email',
        'e-mail'
      ]) ||
      firstInput(),
      DATA.email
    );
  }

  function fillAddress() {
    return setValue(
      findInput([
        'address',
        'street'
      ]) ||
      firstInput(),
      DATA.address
    );
  }

  function fillName() {
    const nameField =
      findInput([
        'name',
        'person'
      ]) ||
      firstInput();

    const locationField =
      findInput([
        'city',
        'state',
        'zip',
        'location'
      ]) ||
      secondInput();

    let changed =
      setValue(
        nameField,
        DATA.fullName
      );

    if (!locationField) {
      return changed;
    }

    if (KIND === 'name_city') {
      changed =
        setValue(
          locationField,
          DATA.city
        ) ||
        changed;
    } else if (
      KIND === 'name_location'
    ) {
      changed =
        setValue(
          locationField,
          DATA.location
        ) ||
        changed;
    } else if (
      KIND === 'name_address'
    ) {
      changed =
        setValue(
          locationField,
          DATA.address
        ) ||
        changed;
    }

    return changed;
  }

  function schedule(fn) {
    /*
     * Fill only once.
     *
     * Repeated delayed fills were causing a
     * Phone search value to be inserted into
     * another tab if the user switched tabs
     * after TraceLock finished the initial
     * autofill.
     */
    setTimeout(fn, 700);
  }

  if (KIND === 'phone') {
    clickTab('Phone');
    schedule(fillPhone);
    return;
  }

  if (KIND === 'email') {
    clickTab('Email');
    schedule(fillEmail);
    return;
  }

  if (
    KIND === 'address' ||
    KIND === 'previous_address'
  ) {
    clickTab('Address');
    schedule(fillAddress);
    return;
  }

  clickTab('Name');
  schedule(fillName);
})();
''';

    await controller.executeScript(script);
  }

  String _escapeJs(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n');
  }

  @override
  void dispose() {
    loadingSubscription?.cancel();
    // controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final navigator = Navigator.of(context);

            try {
              WebviewController.releaseFocus();
              await Future<void>.delayed(const Duration(milliseconds: 150));
            } catch (_) {}

            if (!mounted) {
              return;
            }

            navigator.pop();
          },
        ),
        title: Text(widget.sourceName),
      ),
      body: errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not open '
                  '${widget.sourceName}.'
                  '\n\n$errorMessage',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : !isReady
          ? const Center(child: CircularProgressIndicator())
          : Webview(
              controller,
              permissionRequested:
                  (url, permissionKind, isUserInitiated) async {
                    return WebviewPermissionDecision.deny;
                  },
            ),
    );
  }
}
