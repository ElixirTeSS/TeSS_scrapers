Gem::Specification.new do |s|
  s.name        = 'tessdata'
  s.version     = '0.0.1'
  s.date        = '2015-10-15'
  s.summary     = 'Libraries for uploading files to http://tess.oerc.ox.ac.uk'
  s.description = 'Uses the a Custom RoR API on http://tess.oerc.ox.ac.uk to upload data in the format being used by the TeSS project.'
  s.authors     = ['Milo Thurston','Niall Beard']
  s.email       = 'milo.thurston@oerc.ox.ac.uk'
  s.files       = ['lib/upload.rb','lib/material.rb']
  s.homepage    = 'https://github.com/ElixirUK/newtessscraper'
  s.license     = 'BSD'
end