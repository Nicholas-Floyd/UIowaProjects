from flask import render_template

def render_template_with_prefix(prefix):
    def _render_template(template_name, **kwargs):
        return render_template(f'{prefix}/{template_name}', **kwargs)
    return _render_template