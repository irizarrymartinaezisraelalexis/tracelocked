import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScanWebViewScreen extends StatefulWidget {
  const ScanWebViewScreen({
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
  State<ScanWebViewScreen> createState() => _ScanWebViewScreenState();
}

class _ScanWebViewScreenState extends State<ScanWebViewScreen> {
  late final WebViewController controller;

  int loadingProgress = 0;
  bool isFilling = false;

  bool spokeoAutofillRunning = false;
  bool spokeoAutofillCompleted = false;

  String get firstName => widget.profile['first_name']?.toString() ?? '';

  String get lastName => widget.profile['last_name']?.toString() ?? '';

  String get fullName => '$firstName $lastName'.trim();

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

  String get normalizedQueryKind => widget.queryKind.trim().toLowerCase();

  bool get isTruePeopleSearch {
    final name = widget.sourceName.toLowerCase();

    final url = widget.sourceUrl.toLowerCase();

    return name.contains('truepeoplesearch') ||
        name.contains('true people search') ||
        url.contains('truepeoplesearch.com');
  }

  bool get isWhitepages {
    final name = widget.sourceName.toLowerCase();

    final url = widget.sourceUrl.toLowerCase();

    return name.contains('whitepages') || url.contains('whitepages.com');
  }

  bool get isSpokeo {
    final name = widget.sourceName.toLowerCase();

    final url = widget.sourceUrl.toLowerCase();

    return name.contains('spokeo') || url.contains('spokeo.com');
  }

  String get initialUrl {
    if (isWhitepages) {
      if (normalizedQueryKind == 'phone') {
        return 'https://www.whitepages.com/reverse-phone';
      }

      if (normalizedQueryKind == 'address' ||
          normalizedQueryKind == 'previous_address') {
        return 'https://www.whitepages.com/reverse-address';
      }

      return 'https://www.whitepages.com/';
    }

    return widget.sourceUrl;
  }

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) {
              return;
            }

            setState(() {
              loadingProgress = progress;
            });
          },
          onPageStarted: (url) {
            debugPrint('WEBVIEW START: $url');
          },
          onPageFinished: (url) async {
            debugPrint('WEBVIEW FINISH: $url');

            await Future<void>.delayed(const Duration(milliseconds: 700));

            await _attemptAutofill();

            await Future<void>.delayed(const Duration(milliseconds: 1200));

            await _attemptAutofill();
          },
          onNavigationRequest: (request) {
            debugPrint('WEBVIEW NAV: ${request.url}');

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint(
              'WEBVIEW ERROR: '
              '${error.errorCode} '
              '${error.description}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  Future<void> _attemptAutofill() async {
    if (isFilling) {
      return;
    }

    isFilling = true;

    try {
      if (isTruePeopleSearch) {
        await _fillTruePeopleSearch();
      } else if (isWhitepages) {
        await _fillWhitepages();
      } else if (isSpokeo) {
        await _fillSpokeo();
      } else {
        await _fillGenericSource();
      }
    } catch (error) {
      debugPrint('AUTOFILL ERROR: $error');
    } finally {
      isFilling = false;
    }
  }

  Future<void> _fillTruePeopleSearch() async {
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
    if (!el) return false;

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
    const list = inputs();

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
    const list = inputs();

    return list.length > 0
      ? list[0]
      : null;
  }

  function secondInput() {
    const list = inputs();

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
    setTimeout(fn, 350);
    setTimeout(fn, 850);
    setTimeout(fn, 1500);
    setTimeout(fn, 2500);
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

    await controller.runJavaScript(script);
  }

  Future<void> _fillWhitepages() async {
    final script =
        '''
(function() {
  const KIND =
    '${_escapeJs(normalizedQueryKind)}';

  const DATA = {
    fullName: '${_escapeJs(fullName)}',
    phone: '${_escapeJs(phone)}',
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
    if (!el) return false;

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

  function fields() {
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

  function findField(words) {
    const list = fields();

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

  function firstField() {
    const list = fields();

    return list.length > 0
      ? list[0]
      : null;
  }

  function secondField() {
    const list = fields();

    return list.length > 1
      ? list[1]
      : null;
  }

  function fillPhone() {
    return setValue(
      findField([
        'phone',
        'number',
        'tel'
      ]) ||
      firstField(),
      DATA.phone
    );
  }

  function fillAddress() {
    return setValue(
      findField([
        'address',
        'street'
      ]) ||
      firstField(),
      DATA.address
    );
  }

  function fillPeople() {
    const nameField =
      findField([
        'name',
        'person'
      ]) ||
      firstField();

    const locationField =
      findField([
        'city',
        'state',
        'zip',
        'location'
      ]) ||
      secondField();

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
    setTimeout(fn, 350);
    setTimeout(fn, 850);
    setTimeout(fn, 1500);
    setTimeout(fn, 2500);
  }

  if (KIND === 'phone') {
    schedule(fillPhone);
    return;
  }

  if (
    KIND === 'address' ||
    KIND === 'previous_address'
  ) {
    schedule(fillAddress);
    return;
  }

  schedule(fillPeople);
})();
''';

    await controller.runJavaScript(script);
  }

  Future<void> _fillSpokeo() async {
    if (spokeoAutofillCompleted || spokeoAutofillRunning) {
      return;
    }

    spokeoAutofillRunning = true;

    try {
      String targetUrl;

      switch (normalizedQueryKind) {
        case 'phone':
          targetUrl = 'https://www.spokeo.com/reverse-phone-lookup';
          break;

        case 'email':
          targetUrl = 'https://www.spokeo.com/email-search';
          break;

        case 'address':
        case 'previous_address':
          targetUrl = 'https://www.spokeo.com/reverse-address-search';
          break;

        default:
          targetUrl = 'https://www.spokeo.com/';
          break;
      }

      final currentUrl = await controller.currentUrl();

      final currentUri = currentUrl == null ? null : Uri.tryParse(currentUrl);

      final targetUri = Uri.parse(targetUrl);

      final currentPath = currentUri?.path ?? '';

      final targetPath = targetUri.path;

      /*
       * Spokeo's actual routes discovered
       * from the live page:
       *
       * NAME    /
       * EMAIL   /email-search
       * PHONE   /reverse-phone-lookup
       * ADDRESS /reverse-address-search
       *
       * Navigate directly instead of trying
       * to click the visible tabs.
       */
      if (currentPath != targetPath) {
        await controller.loadRequest(targetUri);

        /*
         * Do not mark the task complete.
         * onPageFinished will call
         * _attemptAutofill() again on the
         * correct Spokeo page.
         */
        return;
      }

      /*
       * We are now on the correct Spokeo
       * search page. Give its DOM time to
       * settle before filling.
       */
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      final fillScript =
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
      .replace(/\\s+/g, ' ')
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

  function fields() {
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
      el.getAttribute('title'),
      el.getAttribute('data-testid')
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
          {
            bubbles: true
          }
        )
      );

      el.dispatchEvent(
        new Event(
          'change',
          {
            bubbles: true
          }
        )
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  function findField(words) {
    const list =
      fields();

    for (
      let i = 0;
      i < list.length;
      i++
    ) {
      const description =
        describe(
          list[i]
        );

      for (
        let j = 0;
        j < words.length;
        j++
      ) {
        if (
          description.includes(
            norm(words[j])
          )
        ) {
          return list[i];
        }
      }
    }

    return null;
  }

  function firstField() {
    const list =
      fields();

    return list.length > 0
      ? list[0]
      : null;
  }

  function secondField() {
    const list =
      fields();

    return list.length > 1
      ? list[1]
      : null;
  }

  if (KIND === 'phone') {
    const field =
      findField([
        'phone',
        'number',
        'tel'
      ]) ||
      firstField();

    setValue(
      field,
      DATA.phone
    );

    return;
  }

  if (KIND === 'email') {
    const field =
      findField([
        'email',
        'e-mail'
      ]) ||
      firstField();

    setValue(
      field,
      DATA.email
    );

    return;
  }

  if (
    KIND === 'address' ||
    KIND === 'previous_address'
  ) {
    /*
     * We are already on Spokeo's dedicated
     * /reverse-address-search page.
     *
     * Therefore the primary visible search
     * input belongs to the Address search.
     */
    const field =
      findField([
        'address',
        'street',
        'location'
      ]) ||
      firstField();

    setValue(
      field,
      DATA.address
    );

    return;
  }

  const nameField =
    findField([
      'name',
      'person'
    ]) ||
    firstField();

  setValue(
    nameField,
    DATA.fullName
  );

  const locationField =
    findField([
      'city',
      'state',
      'zip',
      'location'
    ]) ||
    secondField();

  if (!locationField) {
    return;
  }

  if (KIND === 'name_city') {
    setValue(
      locationField,
      DATA.city
    );
  } else if (
    KIND === 'name_location'
  ) {
    setValue(
      locationField,
      DATA.location
    );
  } else if (
    KIND === 'name_address'
  ) {
    setValue(
      locationField,
      DATA.address
    );
  }
})();
''';

      await controller.runJavaScript(fillScript);

      spokeoAutofillCompleted = true;

      debugPrint(
        'SPOKEO AUTOFILL COMPLETE: '
        '$normalizedQueryKind',
      );
    } catch (error) {
      debugPrint('SPOKEO AUTOFILL ERROR: $error');
    } finally {
      spokeoAutofillRunning = false;
    }
  }

  Future<void> _fillGenericSource() async {
    final script =
        '''
(function() {
  const KIND =
    '${_escapeJs(normalizedQueryKind)}';

  const DATA = {
    fullName: '${_escapeJs(fullName)}',
    phone: '${_escapeJs(phone)}',
    email: '${_escapeJs(email)}',
    location: '${_escapeJs(location)}',
    address: '${_escapeJs(fullAddress)}'
  };

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
      rect.width > 0 &&
      rect.height > 0
    );
  }

  function setValue(el, value) {
    if (!el || !value) {
      return false;
    }

    try {
      el.focus();
      el.value = value;

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

  const fields =
    Array.from(
      document.querySelectorAll(
        'input:not([type="hidden"]), textarea'
      )
    ).filter(visible);

  if (fields.length === 0) {
    return;
  }

  if (KIND === 'phone') {
    setValue(
      fields[0],
      DATA.phone
    );
    return;
  }

  if (KIND === 'email') {
    setValue(
      fields[0],
      DATA.email
    );
    return;
  }

  if (
    KIND === 'address' ||
    KIND === 'previous_address'
  ) {
    setValue(
      fields[0],
      DATA.address
    );
    return;
  }

  setValue(
    fields[0],
    DATA.fullName
  );

  if (
    fields.length > 1 &&
    (
      KIND === 'name_city' ||
      KIND === 'name_location'
    )
  ) {
    setValue(
      fields[1],
      DATA.location
    );
  }

  if (
    fields.length > 1 &&
    KIND === 'name_address'
  ) {
    setValue(
      fields[1],
      DATA.address
    );
  }
})();
''';

    await controller.runJavaScript(script);
  }

  String _escapeJs(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  Future<void> retryAutofill() async {
    await _attemptAutofill();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TraceLock attempted to fill the current search form.'),
      ),
    );
  }

  Future<void> goBack() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
      return;
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> goForward() async {
    if (await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.sourceName),
        actions: [
          IconButton(
            tooltip: 'Fill search fields',
            onPressed: retryAutofill,
            icon: const Icon(Icons.auto_fix_high),
          ),
          IconButton(
            tooltip: 'Forward',
            onPressed: goForward,
            icon: const Icon(Icons.arrow_forward),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: () {
              controller.reload();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (loadingProgress < 100)
            LinearProgressIndicator(value: loadingProgress / 100),
          Expanded(child: WebViewWidget(controller: controller)),
        ],
      ),
    );
  }
}
