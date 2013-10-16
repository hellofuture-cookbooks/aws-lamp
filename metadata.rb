name             'aws-lamp'
maintainer       'Hello Future Ltd'
maintainer_email 'hello@hellofutu.re'
license          'Apache License'
description      'Installs/Configures LAMP stack on AWS'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "apache2"
depends "mysql"
depends "php"
depends "aws"