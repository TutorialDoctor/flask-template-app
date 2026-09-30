def register_filters(app):

    @app.template_filter("reverse")
    def reverse_filter(s):
        return s[::-1]

    @app.template_filter("upcase")
    def caps(text):
        try:
            return text.upper()
        except Exception:
            return ""

    @app.template_filter("phone")
    def phone_format(n):
        try:
            return format(int(n[:-1]), ",").replace(",", "-") + n[-1]
        except Exception:
            return ""