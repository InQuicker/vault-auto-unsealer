FROM ruby:2.4.0-onbuild

CMD ["bundle", "exec", "ruby", "vault-auto-unsealer.rb"]
