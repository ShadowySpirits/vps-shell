vod=false
mkv=false
waf=false

ARGS=`getopt -o "ao:" -l "with-vod,enable-mkv,with-waf" -n "nginx_install.sh" -- "$@"`
eval set -- "${ARGS}"
while true; do
    case "${1}" in
        --with-vod)
        shift;
        vod=true
        ;;
        --enable-mkv)
        shift;
        mkv=true
        ;;
        --with-waf)
        shift;
        waf=true
        ;;
        --)
        shift;
        break;
        ;;
    esac
done


sudo apt update
sudo apt install -y build-essential autoconf automake libatomic-ops-dev libgeoip-dev libbrotli-dev curl git unzip

mkdir ~/nginx
cd ~/nginx

# Nginx 1.17.1
wget https://nginx.org/download/nginx-1.17.1.tar.gz
tar zxf nginx-1.17.1.tar.gz && rm nginx-1.17.1.tar.gz

# SPDY, HTTP2 HPACK, Dynamic TLS Record, Fix Http2 Push Error Patch
pushd nginx-1.17.1
curl https://raw.githubusercontent.com/kn007/patch/master/nginx.patch | patch -p1
popd

# Strict-SNI Patch
pushd nginx-1.17.1
curl https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_strict-sni_1.15.10.patch | patch -p1
popd

# Auto using PRIORITIZE CHACHA patch
pushd nginx-1.17.1
curl https://raw.githubusercontent.com/kn007/patch/master/nginx_auto_using_PRIORITIZE_CHACHA.patch | patch -p1
popd

# OpenSSL 1.1.1c
wget https://www.openssl.org/source/openssl-1.1.1c.tar.gz
tar zxf openssl-1.1.1c.tar.gz && rm zxf openssl-1.1.1c.tar.gz

# OpenSSL Patch
pushd openssl-1.1.1c
curl https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-1.1.1c-chacha_draft.patch | patch -p1
popd

pushd openssl-1.1.1c
curl https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-1.1.1c-prioritize_chacha_draft.patch | patch -p1
popd

# jemalloc
git clone https://github.com/jemalloc/jemalloc.git
pushd jemalloc
./autogen.sh
make -j$(nproc --all)
touch doc/jemalloc.html
touch doc/jemalloc.3
sudo make install
echo '/usr/local/lib' | sudo tee /etc/ld.so.conf.d/local.conf
sudo ldconfig
popd

# zlib
#git clone https://github.com/cloudflare/zlib.git # Cloudflare ver
wget https://zlib.net/zlib-1.2.11.tar.gz
tar xzvf zlib-1.2.11.tar.gz && rm zlib-1.2.11.tar.gz
mv zlib-1.2.11 zlib
pushd zlib
./configure
make && sudo make install
popd

# pcre
wget https://ftp.pcre.org/pub/pcre/pcre-8.43.zip
unzip pcre-8.43.zip && rm pcre-8.43.zip
mv pcre-8.43 pcre

# ngx_brotli
git clone https://github.com/eustas/ngx_brotli.git
pushd ngx_brotli
git submodule update --init
popd

# LuaJit
wget https://github.com/openresty/luajit2/archive/v2.1-20190626.tar.gz
tar xzvf v2.1-20190626.tar.gz && rm v2.1-20190626.tar.gz
mv luajit2-2.1-20190626 luajit-2.1
pushd luajit-2.1
make && sudo make install
ldconfig
popd
export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.1 
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1

# lua cjson
wget https://github.com/openresty/lua-cjson/archive/2.1.0.7.tar.gz
tar xzvf 2.1.0.7.tar.gz && rm 2.1.0.7.tar.gz
mv lua-cjson-2.1.0.7 lua-cjson
pushd luajit-2.1
make && sudo make install
popd

# lua module
wget https://github.com/openresty/lua-nginx-module/archive/v0.10.15.tar.gz
tar zxf v0.10.15.tar.gz && rm v0.10.15.tar.gz
mv lua-nginx-module-0.10.15 lua-nginx-module

# NDK
wget https://github.com/simplresty/ngx_devel_kit/archive/v0.3.1rc1.tar.gz
tar zxf v0.3.1rc1.tar.gz && rm v0.3.1rc1.tar.gz
mv ngx_devel_kit-0.3.1rc1 ngx_devel_kit

if $vod
then
  # vod module
  wget https://github.com/kaltura/nginx-vod-module/archive/1.24.tar.gz
  tar zxf 1.24.tar.gz && rm 1.24.tar.gz
  mv nginx-vod-module-1.24 nginx-vod-module
  if $mkv
  then
    pushd nginx-vod-module
    curl https://gist.githubusercontent.com/ShadowySpirits/d2e0e056f838ad204a10e6c38c2375fa/raw/8af12279476cd4feda4e64458e857953eaf12d7c/nginx-vod-module_mkv_support.patch | patch -p1
    popd
  fi
fi

# libmaxminddb
wget https://github.com/maxmind/libmaxminddb/releases/download/1.3.2/libmaxminddb-1.3.2.tar.gz
tar zxf libmaxminddb-1.3.2.tar.gz && rm libmaxminddb-1.3.2.tar.gz
mv libmaxminddb-1.3.2 libmaxminddb
pushd libmaxminddb
./configure
make && sudo make install
sudo ldconfig
popd

# GeoIP2 module
wget https://github.com/leev/ngx_http_geoip2_module/archive/3.2.tar.gz
tar zxf 3.2.tar.gz && rm 3.2.tar.gz
mv ngx_http_geoip2_module-3.2 ngx_http_geoip2_module

# nginx-sorted-querystring-module
wget https://github.com/wandenberg/nginx-sorted-querystring-module/archive/0.3.tar.gz
tar zxf 0.3.tar.gz && rm 0.3.tar.gz
mv nginx-sorted-querystring-module-0.3 nginx-sorted-querystring-module

# ngx_http_substitutions_filter_module
wget https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v0.6.4.tar.gz
tar zxf v0.6.4.tar.gz && rm v0.6.4.tar.gz
mv ngx_http_substitutions_filter_module-0.6.4 ngx_http_substitutions_filter_module

cd nginx-1.17.1

sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

if $vod
then
./configure \
--with-cc-opt='-g -O3 -m64 -march=native -ffast-math -DTCP_FASTOPEN=23 -fPIE -fstack-protector-strong -flto -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wno-unused-parameter -fno-strict-aliasing -fPIC -D_FORTIFY_SOURCE=2 -gsplit-dwarf' \
--with-ld-opt='-lrt -L /usr/local/lib -ljemalloc -Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -fPIC' \
--user=www-data \
--group=www-data \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--http-log-path=/home/wwwlogs/access.log \
--error-log-path=/home/wwwlogs/error.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/run/nginx.pid \
--modules-path=/usr/lib/nginx/modules \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-threads \
--with-file-aio \
--with-pcre-jit \
--with-http_v2_module \
--with-http_ssl_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_slice_module \
--with-http_geoip_module \
--with-http_gunzip_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_gzip_static_module \
--with-http_degradation_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_random_index_module \
--with-http_auth_request_module \
--with-stream \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-stream_realip_module \
--with-http_v2_hpack_enc \
--with-http_spdy_module \
--with-pcre=../pcre \
--with-zlib=../zlib \
--with-libatomic \
--with-openssl=../openssl-1.1.1c \
--with-openssl-opt='zlib -march=native -ljemalloc -Wl,-flto' \
--add-module=../ngx_brotli \
--add-module=../ngx_devel_kit \
--add-module=../lua-nginx-module \
--add-module=../ngx_http_geoip2_module \
--add-module=../nginx-sorted-querystring-module \
--add-module=../ngx_http_substitutions_filter_module \
--add-module=../nginx-vod-module
else
./configure \
--with-cc-opt='-g -O3 -m64 -march=native -ffast-math -DTCP_FASTOPEN=23 -fPIE -fstack-protector-strong -flto -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wno-unused-parameter -fno-strict-aliasing -fPIC -D_FORTIFY_SOURCE=2 -gsplit-dwarf' \
--with-ld-opt='-lrt -L /usr/local/lib -ljemalloc -Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -fPIC' \
--user=www-data \
--group=www-data \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--http-log-path=/home/wwwlogs/access.log \
--error-log-path=/home/wwwlogs/error.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/run/nginx.pid \
--modules-path=/usr/lib/nginx/modules \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-threads \
--with-file-aio \
--with-pcre-jit \
--with-http_v2_module \
--with-http_ssl_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_slice_module \
--with-http_geoip_module \
--with-http_gunzip_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_gzip_static_module \
--with-http_degradation_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_random_index_module \
--with-http_auth_request_module \
--with-stream \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-stream_realip_module \
--with-http_v2_hpack_enc \
--with-http_spdy_module \
--with-pcre=../pcre \
--with-zlib=../zlib \
--with-libatomic \
--with-openssl=../openssl-1.1.1c \
--with-openssl-opt='zlib -march=native -ljemalloc -Wl,-flto' \
--add-module=../ngx_brotli \
--add-module=../ngx_devel_kit \
--add-module=../lua-nginx-module \
--add-module=../ngx_http_geoip2_module \
--add-module=../nginx-sorted-querystring-module \
--add-module=../ngx_http_substitutions_filter_module
fi

make -j$(nproc --all)
sudo make install

# ngx_lua_waf
cd /etc/nginx
if $waf
then
  sudo git clone https://github.com/xzhih/ngx_lua_waf.git waf 
  sudo mkdir -p /home/wwwlogs/waf
fi
sudo mkdir /home/wwwroot
sudo mkdir /etc/nginx/sites-enabled
sudo chown -R www-data:www-data /home/wwwlogs
sudo chown -R www-data:www-data /home/wwwroot

if $waf
then
sudo tee /etc/nginx/waf/config.lua << EOF
config_waf_enable = "on"
config_log_dir = "/home/wwwlogs/waf"
config_rule_dir = "/etc/nginx/waf/wafconf"
config_white_url_check = "on"
config_white_ip_check = "on"
config_black_ip_check = "on"
config_url_check = "on"
config_url_args_check = "on"
config_user_agent_check = "on"
config_cookie_check = "on"
config_cc_check = "on"
config_cc_rate = "60/60" -- count per XX seconds
config_post_check = "on"
config_waf_output = "html"
config_waf_redirect_url = "/captcha" -- only enable when config_waf_output = "redirect"
config_output_html=[[
<html><head><meta name="viewport"content="initial-scale=1,minimum-scale=1,width=device-width"><title>WAF Alert</title><style>body{font-size:100%;background-color:#ce3426;color:#fff;margin:15px}@media(max-width:420px){body{font-size:90%}}</style></head><body><div style=""><div style=" text-align: center;margin-top: 250px;"><h1>WAF</h1><h2>Your request has been blocked</h2></div></div></body></html>
]]
EOF


sudo tee /etc/nginx/sites-enabled/waf.conf << EOF
lua_load_resty_core off;
lua_shared_dict limit 20m;
lua_package_path "/etc/nginx/waf/?.lua";
init_by_lua_file "/etc/nginx/waf/init.lua";
access_by_lua_file "/etc/nginx/waf/access.lua";
EOF
fi

# nginx conf
sudo tee /etc/nginx/nginx.conf << EOF
user www-data www-data;
pid /run/nginx.pid;
worker_processes auto;
worker_rlimit_nofile 65535;

events {
  use epoll;
  multi_accept on;
  worker_connections 65535;
}

http {
  charset utf-8;
  sendfile on;
  aio threads;
  directio 512k;
  tcp_nopush on;
  tcp_nodelay on;
  server_tokens off;
  log_not_found off;
  types_hash_max_size 2048;
  client_max_body_size 0 ;

  # SSL
  strict_sni                  on;
  strict_sni_header           on;
  ssl_protocols               TLSv1.2 TLSv1.3;
  ssl_ecdh_curve              X25519:P-256:P-384:P-224:P-521;
  ssl_ciphers                 '[ECDHE-ECDSA-AES128-GCM-SHA256|ECDHE-ECDSA-CHACHA20-POLY1305|ECDHE-RSA-AES128-GCM-SHA256|ECDHE-RSA-CHACHA20-POLY1305]:ECDHE+AES128:RSA+AES128:ECDHE+AES256:RSA+AES256:ECDHE+3DES:RSA+3DES';
  ssl_prefer_server_ciphers   on;
  ssl_early_data              on;
  proxy_set_header Early-Data \$ssl_early_data;

  # MIME
  include mime.types;
  default_type application/octet-stream;

  # Logging
  access_log /home/wwwlogs/access.log;
  error_log /home/wwwlogs/error.log;

  # Gzip
  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";

  # Brotli
  brotli on;
  brotli_static on;
  brotli_min_length 20;
  brotli_buffers 32 8k;
  brotli_comp_level 6;
  brotli_types text/plain text/css text/xml text/javascript application/javascript application/x-javascript application/json application/xml application/rss+xml application/atom+xml image/svg+xml;

  include /etc/nginx/sites-enabled/*;
}
EOF

# nginx service
sudo tee /lib/systemd/system/nginx.service <<EOF
[Unit]
Description=A high performance web server and a reverse proxy server
After=network.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

sudo chown -R www-data:www-data /etc/nginx

sudo systemctl unmask nginx.service
sudo systemctl daemon-reload
sudo systemctl enable nginx
sudo systemctl start nginx
