require './informer'


informer = Informer.new('/tmp/pivotal.yml')
informer.for_realsies = false 
informer.send_tag('[CK] [56889564] SRL Search Bar unresponsive after viewing "Sorry! We dont recognize that search term." dialog', "\n99.99.99-TESTING\n")
