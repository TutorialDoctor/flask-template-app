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

# Notes

- You can use the roles routes and folder structure as a basis for CRUD for new Objects. It was based on the Items setup (one method with 4 CRUD templates with a partial for the admin table)



<!-- {% with user=current_user %}
  {% include './shared/nav.html' %}
{% endwith %} -->
