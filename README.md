# Todo

- [ ] Add bcrypt and argon
- [ ] Complete Component Library


**Start the App**

`uv run main.py`


**Seed the database**

`python3 -m scripts.seed`


# File Structure

```
static/
templates/
app.py
auth.py
db_init.py
errors.py
extensions.py
filters.py
models.py
routes.py
requirements.txt
data.db
```

<!-- {% with user=current_user %}
  {% include './shared/nav.html' %}
{% endwith %} -->
