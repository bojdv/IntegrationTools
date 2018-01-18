jruby -S rails tmp:clear
jruby -S rails log:clear
jruby -S rails assets:clobber
jruby -S rails assets:precompile RAILS_ENV=production
jruby -S rails server -b 0.0.0.0 -p 3000 -e production