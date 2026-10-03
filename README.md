# Todo

- [ ] Add bcrypt and argon
- [ ] Complete Component Library
- [ ] Document all methods
- [ ] Attachment Uploads


**Start the App**

`uv run main.py`

**Seed the database**

`python3 -m scripts.seed`

# File Structure

```
static/
templates/
scripts/
modules/
main.py
config.py
db_init.py
extensions.py
helpers.py
models.py
routes.py
data.db
```

# Notes

- You can use the roles routes and folder structure as a basis for CRUD for new Objects. It was based on the Items setup (one method with 4 CRUD templates with a partial for the admin table)


<!-- {% with user=current_user %}
  {% include './shared/nav.html' %}
{% endwith %} -->
