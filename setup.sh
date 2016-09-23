
et up phusion passenger test env
#
# ryan@rchapman.org
# Fri Sep 23 03:47:41 UTC 2016

RUBY_REQUIRED_VERSION="1.9.3p551"

TRUE=0
FALSE=1

function logit
{
    if [[ "${1}" == "FATAL" ]]; then
        fatal="FATAL"
        shift
    fi
    echo -n "$(date '+%b %d %H:%M:%S.%N %Z') $(basename -- $0)[$$]: "
    if [[ "${fatal}" == "FATAL" ]]; then echo -n "${fatal} "; fi
    echo "$*"
    if [[ "${fatal}" == "FATAL" ]]; then exit 1; fi
}

function run_ignerr
{
    _run warn $*
}

function run
{
    _run fatal $*
}

function _run
{
    if [[ $1 == fatal ]]; then
        errors_fatal=$TRUE
    else
        errors_fatal=$FALSE
    fi
    shift
    logit "$*"
    eval "$*"
    rc=$?
    logit "$* returned $rc"
    # fail hard and fast
    if [[ $rc != 0 && $errors_fatal == $TRUE ]]; then
        pwd
        exit 1
    fi
    return $rc
}

logit "Installing RVM and Ruby"
run "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
run "curl -sSL https://get.rvm.io | bash -s stable --ruby=1.9.3"
run "source /usr/local/rvm/scripts/rvm"
logit "Installing RVM and Ruby: done"

logit "Checking that ruby version is $RUBY_REQUIRED_VERSION"
ruby -v | grep "${RUBY_REQUIRED_VERSION}" &>/dev/null || logit FATAL "Checking that ruby version is $RUBY_REQUIRED_VERSION: no"
logit "Checking that ruby version is $RUBY_REQUIRED_VERSION: yes"

logit "Installing rack"
gem install rack --version 1.3.2
logit "Installing rack: done"

logit "Installing passenger"
gem install passenger --version 3.0.19 --no-rdoc --no-ri
logit "Installing passenger: done"

logit "Installing Apache2 and mod_passenger dependencies"
run "yum -y install httpd curl-devel httpd-devel apr-devel apr-util-devel"
logit "Installing Apache2 and mod_passenger dependencies: done"

logit "Building and installing mod_passenger"
run "passenger-install-apache2-module --auto"
logit "Building and installing mod_passenger: done"

run "mkdir -p /www/public"

HTTPD_CONF=/etc/httpd/conf.d/passenger.conf
logit "Building apache configs"
run "echo 'LoadModule passenger_module /usr/local/rvm/gems/ruby-1.9.3-p551/gems/passenger-3.0.19/ext/apache2/mod_passenger.so' >$HTTPD_CONF"
run "echo 'PassengerRoot /usr/local/rvm/gems/ruby-1.9.3-p551/gems/passenger-3.0.19' >>$HTTPD_CONF"
run "echo 'PassengerRuby /usr/local/rvm/wrappers/ruby-1.9.3-p551/ruby' >>$HTTPD_CONF"
run "echo 'PassengerMinInstances 1' >>$HTTPD_CONF"
run "echo 'PassengerMaxPoolSize 1' >>$HTTPD_CONF"
run "echo >>$HTTPD_CONF"
run "echo '<VirtualHost *:80>' >>$HTTPD_CONF"
run "echo '   ServerName test.rchapman.org' >>$HTTPD_CONF"
run "echo '   DocumentRoot /www/fake_work_app/public' >>$HTTPD_CONF"
run "echo '   <Directory /www/fake_work_app/public>' >>$HTTPD_CONF"
run "echo '      AllowOverride all' >>$HTTPD_CONF"
run "echo '      Options -MultiViews' >>$HTTPD_CONF"
run "echo '   </Directory>' >>$HTTPD_CONF"
run "echo '</VirtualHost>' >>$HTTPD_CONF"
run "rm -f /etc/httpd/conf.d/welcome.conf 2>/dev/null"
logit "Building apache configs: done"

logit "Disabling selinux"
run "echo 0 > /selinux/enforce"
logit "Disabling selinux: done"

logit "Cloning fake_work_app"
run "yum -y install git"
run_ignerr "rm -rf /www/fake_work_app"
run "git clone https://github.com/jrochkind/fake_work_app.git /www/fake_work_app"
logit "Cloning fake_work_app: done"

logit "Running bundler in /www/fake_work_app"
run "cd /www/fake_work_app"
run "gem install bundler"
run "bundler install"
logit "Running bundler in /www/fake_work_app: done"

logit "Restarting apache"
run "service httpd restart"
logit "Restarting apache: done"

logit "Installing htop"
run "cd /tmp"
run "wget ftp://195.220.108.108/linux/dag/redhat/el6/en/x86_64/dag/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm"
run "yum -y install htop"
logit "Installing htop: done"

logit "Installing perf"
run "yum -y install perf"
logit "Installing perf: done"
