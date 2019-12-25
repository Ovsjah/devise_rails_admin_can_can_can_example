# Rails 6 (and 5): User Accounts with 3 types of Roles – Devise, Rails Admin, CanCanCan


## About

The admin roles grant access to the admin panel built with Rails Admin. Devise gem handles authentication, and CanCanCan gem does authorization.


## Plan

1. Create User model using Devise gem.
2. Set up authentication by Devise gem.
3. Generate views, links and controllers for Devise’s Users.
4. Create rails_admin dashboard.
5. Set up authorization using Cancancan.
6. Give an access to Rails Admin only for admins (superadmin, supervisor) users using Cancancan.
7. Setup mailer for Devise.


### Getting Started

Add to Gemfile:
```
# Authentication
gem 'devise'
# Admin users
gem 'rails_admin', git: 'https://github.com/sferik/rails_admin.git'
# Authorization
gem 'cancancan'
```

Install gems and Devise generator:
```
$ bundle
$ rails g devise:install
```

Install fancy flash support:
```
$ yarn add toastr
```

Import toastr in `app/javascripts/packs/application.js`:
```
global.toastr = require("toastr")
import '../stylesheets/application'
```

Import toastr in `app/javascript/stylesheets/application.scss`:
```
@import 'toastr'
```

Create `app/views/layouts/_flash_msgs.html.erb`:
```
<% unless flash.empty? %>
  <script type="text/javascript">
    <% flash.each do |msg_type, msg| %>
   	  toastr['<%= msg_type.gsub(/alert|notice/, 'alert' => 'error', 'notice' => 'info') %>']('<%= msg %>');
    <% end %>
  </script>
<% end %>
```
and render it into `app/views/layouts/application.html.erb`.

Generate User model:
```
$ rails g devise User
```

Apply changes to the model and migrate:
```
$ rails db:migrate
```

Generate a HomeController with #index and corresponding view
```
$ rails g controller Home index
```

Add `before_action :authenticate_user!` to `app/controllers/application_controller.rb` to restrict access to all resources except HomeController.

Add  `skip_before_action :authenticate_user!, only: :index` to `app/controllers/home_controller.rb`

Run `rails g rails_admin:install`. Now you should get access to Rails Admin panel under /admin in the web browser.

Customize `config/initializers/rails_admin.rb` to use Devise for authentication
```
## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)
```

Use CanCanCan gem to restrict access to some parts of the app. Grant different permissions for specific roles.
```
$ rails g cancan:ability
```

Configure `config/initializers/rails_admin.rb` to use authorization with CanCanCan:
```
## == CancanCan ==
config.authorize_with :cancancan
```
Add role boolean columns to the users table
```
$ rails generate migration add_roles_to_users superadmin_role:boolean supervisor_role:boolean user_role:boolean
```

Define default values for superadmin and supervisor as a false, and true for user_role:
```
class AddRolesToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :superadmin_role, :boolean, default: false
    add_column :users, :supervisor_role, :boolean, default: false
    add_column :users, :user_role, :boolean, default: true
  end
end
```

Apply changes:
```
$ rails db:migrate
```

Create user and verify in rails console:
```
User.first.superadmin_role?
User.first.supervisor_role?
User.first.user_role?
```

Define abilities for user in `app/model/ability.rb`:
```
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.superadmin_role?
      can :manage, :all
      can :access, :rails_admin  # only admin can access Rails Admin
      can :manage, :dashboard    # allow access to dashboard
    end

    if user.supervisor_role?
      can :manage, User
    end
  end
end
```

Apply changes to `app/views/home/index.html.erb` to display content for corresponding role:
```
<% if user_signed_in? %>
  <%= link_to('Edit registration', edit_user_registration_path) %>
  <%= link_to('Logout', destroy_user_session_path, method: :delete) %>

  <% if can? :manage, :dashboard %>
	  <%= link_to('Admin Panel', rails_admin.dashboard_path) %>
  <% end %>
<% else %>
  <%= link_to('Register', new_user_registration_path)  %>
  <%= link_to('Login', new_user_session_path)  %>
<% end %>
```
