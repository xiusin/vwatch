module vwatch

import net.http
import time
import json
import xiusin.vcolor
import os

pub const vwatch_version = 'v0.1.0-alpha'

const releases_url = 'https://api.github.com/repos/xiusin/vwatch/releases/latest'

struct ReleaseResp {
	tag_name string
	name     string
	assets   []Asset
}

struct Asset {
	name                 string
	browser_download_url string
	size                 i64
}

pub fn update_vwatch() ! {
	mut req := http.new_request(.get, vwatch.releases_url, '')
	req.read_timeout = 10 * time.second
	mut resp := req.do()!
	data := json.decode(ReleaseResp, resp.body)!
	if data.tag_name == vwatch.vwatch_version {
		vcolor.yellow('The current version is already the latest version.')
		return
	}

	// 确定文件名
	mut base_name := 'vwatch-${os.user_os()}'
	if os.user_os() == 'windows' {
		base_name += '.exe'
	}

	mut file_url := ''
	for asset in data.assets {
		if asset.name == base_name {
			file_url = asset.browser_download_url
		}
	}

	if file_url.len == 0 {
		vcolor.red('No `${base_name}` found')
		return
	}
	dir := os.dir(os.executable())
	bin_file := os.join_path(dir, base_name)
	http.download_file(file_url, bin_file)!
	os.mv(bin_file, os.executable())!
	vcolor.green('success updated, now version is ${data.tag_name}')
}
