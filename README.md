# MxV

MxV is Momentum's platform for deliberation and discussion of proposals for its first conference scheduled for Febuary 2016. It is a fork of [Consul](https://github.com/consul/consul/), open source eParticipation software originally developed for the Madrid City government and deployed at [decide.madrid.es](https://decide.madrid.es) ([source code](https://github.com/AyuntamientoMadrid/consul)).

MxV has a number of differences from Consul:

* Consul's registration and verification system are disabled. Users must sign up directly to become Momentum members and their credentials will automatically be generated on MxV through a scheduled task.
* MxV disables Consul's voting, budgeting and other systems in the Momentum deployment.
* MxV hides a number of features related to geography unneeded by a national organisation.
* MxV has adapted Consul to work smoothly in a containerised environment using Docker.
* MxV contains Momentum branding and text changes related to the conference.

The choice of Consul was made after a competitor analysis of a number of e-democracy and e-participation systems. Consul was chosen for its feature completeness, openness to forking and adaptation, feature set, accessability and a number of other factors.

## Tech Stack

The application backend is written in the [Ruby language](https://www.ruby-lang.org/) using the [Ruby on Rails](http://rubyonrails.org/) framework.

Frontend tools used include [SCSS](http://sass-lang.com/) over [Foundation](http://foundation.zurb.com/) for the styles.

MxV is a containerised application intended to be deployed by [Kubernetes](http://kubernetes.io/).

## Configuration For Development

### Local

**NOTE**: For more detailed instructions check the [docs](https://github.com/consul/consul/tree/master/doc/en/dev_test_setup.md).

Prerequisites: install Git, Ruby 2.3.2, bundler gem, ghostscript and PostgreSQL (>=9.4).

```
git clone https://github.com/peoplesmomentum/consul.git
cd consul
bundle install
cp config/database.yml.example config/database.yml
cp config/secrets.yml.example config/secrets.yml
bin/rake db:setup
bin/rake db:dev_seed
RAILS_ENV=test rake db:setup
```

Run the app locally:
```
bin/rails s

```

Prerequisites for testing: install PhantomJS >= 1.9.8

Run the tests with:

```
bin/rspec
```

You can use the default admin user from the seeds file:

 **user:** admin@consul.dev
 **pass:** 12345678

But for some actions like voting, you will need a verified user, the seeds file also includes one:

 **user:** verified@consul.dev
 **pass:** 12345678

### Docker

For detailed instructions on [containised development and deployment](https://github.com/PeoplesMomentum/consul/blob/master/doc/en/docker_setup.md) see the relevant documentation.

This methodology is not yet seamless for development environments.

### Customization

See [CUSTOMIZE_ES.md](CUSTOMIZE_ES.md)

### OAuth

To test authentication services with external OAuth suppliers - right now Twitter, Facebook and Google - you'll need to create an "application" in each of the supported platforms and set the *key* and *secret* provided in your *secrets.yml*

In the case of Google, verify that the APIs *Contacts API* and *Google+ API* are enabled for the application.

## License

Code published under AFFERO GPL v3 (see [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt)).
