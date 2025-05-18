= Redmine Public Issue Preview Plugin

== Author
tuandbe (https://github.com/tuandbe)

== Description
Allows generating a time-limited public preview link for issues in Redmine. This enables sharing specific issues with external users without requiring them to have a Redmine account. Attachments on the issue are also accessible via this public link.

== Features
* Generate unique, time-limited public preview links for issues.
* Allow public access to issue details and attachments via the generated link.
* Configurable: administrators can select which trackers are eligible for public previews.
* Permission-based: only users with the "Generate public issue previews" permission can create these links.
* Supports Redmine 5.0.0 and higher.

== Requirements
* Redmine version 5.0.0 or higher.
* Ruby (as required by your Redmine version).
* Bundler.

== Installation (Production Environment)

1.  **Navigate to your Redmine root directory.**
    Example:
    <pre>
    cd /path/to/your/redmine
    </pre>

2.  **Copy the plugin directory into Redmine's `plugins` folder.**
    Download the plugin (e.g., as a ZIP file or using `git clone`) and place it into the `plugins` directory. Ensure the directory name is `redmine_public_preview`.
    <pre>
    # If cloned from git
    git clone https://github.com/tuandbe/redmine_public_preview.git plugins/redmine_public_preview
    # Or if you have the plugin files, copy them
    # cp -r /path/to/downloaded/redmine_public_preview plugins/
    </pre>

3.  **Install plugin dependencies (if any).**
    This plugin primarily relies on Redmine's core gems. However, it's good practice to run bundle install, especially if plugins add their own gems in the future.
    <pre>
    bundle install --without development test
    </pre>
    *Note: If your plugin had specific gems in its own Gemfile, you might need `bundle install` from the plugin's directory, but usually, Redmine plugins manage dependencies via the main Gemfile or checks in `init.rb`.*

4.  **Run plugin migrations.**
    This command will create the necessary database tables for the plugin.
    <pre>
    RAILS_ENV=production bundle exec rake redmine:plugins:migrate
    # Or, for newer Rails syntax often used with Redmine 5:
    # RAILS_ENV=production bundle exec bin/rails redmine:plugins:migrate
    </pre>

5.  **Restart the Redmine application server.**
    This step depends on how you are running Redmine (e.g., Puma, Passenger, Unicorn).
    Example for Puma (if you manage it with `systemd` or a similar tool):
    <pre>
    sudo systemctl restart redmine
    </pre>
    Or, if you use `touch tmp/restart.txt`:
    <pre>
    touch tmp/restart.txt
    </pre>

== Configuration

1.  Log in to Redmine as an administrator.
2.  Navigate to "Administration" -> "Plugins".
3.  Find "Redmine Public Issue Preview Plugin" in the list and click on the "Configure" link.
4.  In the settings page, select the trackers for which you want to allow the generation of public preview links.
5.  Save the settings.

== Usage

1.  **Assign Permissions:**
    *   Go to "Administration" -> "Roles and permissions".
    *   Select a role to which you want to grant permission.
    *   Under the "Issue tracking" section (or "Public Issue Preview" if you used a separate module), check the box for "Generate public issue previews".
    *   Save the changes.

2.  **Generate a Public Preview Link:**
    *   Users with the appropriate permission can open an issue within a project that uses one of the configured trackers.
    *   (The exact location of the "Generate Public Preview" button/link depends on the hook implementation. It's typically found in the issue details view, possibly in the sidebar or context menu.)
    *   Clicking this will generate a unique, time-limited URL.

3.  **Share the Link:**
    *   Copy the generated URL and share it with external users.
    *   These users will be able to view the issue details and download its attachments without logging in, until the link expires.

== Uninstallation

1.  **Navigate to your Redmine root directory.**
    <pre>
    cd /path/to/your/redmine
    </pre>

2.  **Rollback plugin migrations.**
    This will remove the plugin's database tables.
    <pre>
    RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_public_preview VERSION=0
    # Or:
    # RAILS_ENV=production bundle exec bin/rails redmine:plugins:migrate NAME=redmine_public_preview VERSION=0
    </pre>

3.  **Remove the plugin directory.**
    <pre>
    rm -rf plugins/redmine_public_preview
    </pre>

4.  **Restart the Redmine application server.**
    (Refer to step 5 in the Installation section).

== Notes on Patching
This plugin patches Redmine's `AttachmentsController` to allow public access to attachments via the preview token. This is done by:
1.  Directly using `class_eval` on `AttachmentsController` within `init.rb` for immediate patching.
2.  Also, preparing `RedminePublicPreview::Patches::AttachmentsControllerPatch` to be prepended in a `Rails.application.config.to_prepare` block, ensuring it's loaded correctly, especially in development mode for reloading.

Always ensure that patching is done carefully and test thoroughly, as it can affect core Redmine behavior.

== Contributing
Feel free to fork the project and submit pull requests on GitHub:
https://github.com/tuandbe/redmine_public_preview

== License
(Specify your license here, e.g., MIT, GPLv2, etc. If not specified, it's often assumed to be under the same license as Redmine - GPLv2.)
