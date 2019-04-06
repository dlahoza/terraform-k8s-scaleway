provider "scaleway" {
  region  = "${var.region}"
  version = "1.9.2"
}

provider "external" {
  version = "1.0.0"
}

data "scaleway_image" "xenial" {
  architecture = "${var.arch}"
  name         = "Ubuntu Xenial"
}
