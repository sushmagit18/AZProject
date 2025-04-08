module "vnet" {
  source = "./modules/vnet"
}


module "bastion" {
  source             = "./modules/bastion"
  bastion_subnet_id  = module.vnet.bastion_subnet_id
}



module "webservers" {
  source        = "./modules/web-servers"
  web_subnet_id = module.vnet.web_subnet_id
}



module "business-servers" {
  source              = "./modules/business-servers"
  business_subnet_id     = module.vnet.business_subnet_id
}


module "database" {
  source         = "./modules/database"
  data_subnet_id = module.vnet.data_subnet_id
}


module "firewall" {
  source        = "./modules/firewall"
  dmz_subnet_id = module.vnet.dmz_subnet_id
}
