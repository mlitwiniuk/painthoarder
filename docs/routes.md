# Routes Reference

## Public (no auth)
```
GET  /                              pages#welcome
GET  /up                            health check
GET  /pages/:slug                   pages#show (issued pages)
GET  /projects/public               projects#public_index
GET  /p/:token                      projects#restricted (secret token)
```

## Devise
```
/users/sign_in, sign_up, password, confirmation, unlock
```

## Authenticated
```
GET  /dashboard                     dashboard#index (root when signed in)

# Paints (catalog)
GET  /paints                        paints#index (ransack + filters)
GET  /paints/search                 paints#search (FTS, turbo_stream)
GET  /paints/:id                    paints#show
GET  /paints/:id/similar            paints#similar

# User Paints (collection)
GET  /user_paints                   user_paints#index
POST /user_paints                   user_paints#create
GET  /user_paints/:id               user_paints#show
PATCH /user_paints/:id              user_paints#update
DELETE /user_paints/:id             user_paints#destroy
GET  /user_paints/bulk_import       user_paints#bulk_import
POST /user_paints/bulk_search       user_paints#bulk_search
POST /user_paints/bulk_search_from_photo  user_paints#bulk_search_from_photo
GET  /user_paints/color_wheel       user_paints#color_wheel

# Projects
GET  /projects                      projects#index
POST /projects                      projects#create
GET  /projects/:id                  projects#show
PATCH /projects/:id                 projects#update
DELETE /projects/:id                projects#destroy

# Project Updates (nested)
GET  /projects/:project_id/project_updates/new      project_updates#new
POST /projects/:project_id/project_updates           project_updates#create
GET  /projects/:project_id/project_updates/:id/edit  project_updates#edit
PATCH /projects/:project_id/project_updates/:id      project_updates#update
DELETE /projects/:project_id/project_updates/:id     project_updates#destroy

# API (JSON for cascading selects)
GET  /api/brands                    api/brands#index
GET  /api/product_lines             api/product_lines#index
GET  /api/paints                    api/paints#index
GET  /api/paints/:id                api/paints#show
```

## Admin Only
```
Pages CRUD: GET/POST /pages, GET/PATCH/DELETE /pages/:id
```
