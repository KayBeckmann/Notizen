import 'dart:js_interop';

@JS('document.title')
external set _documentTitle(String title);

/// Web-Implementation zum Setzen des Dokumenttitels
void setDocumentTitle(String title) {
  _documentTitle = title;
}
