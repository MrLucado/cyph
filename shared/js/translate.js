var defaultLanguage	= 'en';

var language		= (
	navigator.language ||
	navigator.userLanguage ||
	navigator.browserLanguage ||
	navigator.systemLanguage ||
	defaultLanguage
).toLowerCase();

var languagePair	= language.split('-');

function htmlDecode (value) {
	return $('<div />').html(value).text();
}


if (typeof translations != 'undefined') {
	if (localStorage && localStorage.forceLanguage) {
		language	= localStorage.forceLanguage.toLowerCase();
	}

	if (language == 'nb') {
		language	= 'no';
	}
	if (language == 'zh-cn') {
		language	= 'zh-chs';
	}
	if (language == 'zh-tw') {
		language	= 'zh-cht';
	}


	if (language != defaultLanguage) {
		var o			= {};
		var translation	= translations[language];

		for (var k in translation) {
			o[htmlDecode(k)]	= htmlDecode(translation[k]);
		}

		translation	= o;
		delete o;


		$('[translate]').each(function () {
			var $this	= $(this);
			var ngBind	= $this.attr('ng-bind');
			var html	= $this.html().trim();

			for (var i = 0 ; i < this.attributes.length ; ++i) {
				var value	= this.attributes[i].value;

				if (value) {
					var valueTranslation	= translation[value];

					if (valueTranslation) {
						this.attributes[i].value	= valueTranslation;
					}
				}
			}

			if (ngBind) {
				$this.attr('ng-bind', ngBind.replace(/"([^"]*)"/g, function (match, value) {
					var valueTranslation	= translation[value];

					if (valueTranslation) {
						return '"' + valueTranslation + '"';
					}
					else {
						return match;
					}
				}));
			}

			if (html) {
				$this.html(html.replace(/(.*?)(\{\{.*?\}\}|$)/g, function (match, value, binding) {
					var valueTranslation	= translation[value];

					if (valueTranslation) {
						return valueTranslation + binding;
					}
					else {
						return match;
					}
				}));
			}
		});
	}
}
