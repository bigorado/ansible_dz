1. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает LightHouse.
2. При создании tasks рекомендую использовать модули: `get_url`, `template`, `yum`, `apt`.
3. Tasks должны: скачать статику LightHouse, установить Nginx или любой другой веб-сервер, настроить его конфиг для открытия LightHouse, запустить веб-сервер.
4. Подготовьте свой inventory-файл `prod.yml`.
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
9. Подготовьте README.md-файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-03-yandex` на фиксирующий коммит, в ответ предоставьте ссылку на него.

Ответы:

6.

```shell
TASK [NGINX | Install NGINX] **************************************************************************************************************************************************************************************************
fatal: [lighthouse-01]: FAILED! => {"changed": false, "msg": "No package matching 'nginx' found available, installed or updated", "rc": 126, "results": ["No package matching 'nginx' found available, installed or updated"]}
...ignoring

TASK [NGINX | Create file for lighthouse config] ******************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [NGINX | Create general config] ******************************************************************************************************************************************************************************************
changed: [lighthouse-01]

RUNNING HANDLER [reload-nginx] ************************************************************************************************************************************************************************************************
skipping: [lighthouse-01]

PLAY [Install LightHouse] *****************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Install dependencies] **************************************************************************************************************************************************************************************
changed: [lighthouse-01]

TASK [Lighthouse | Copy from git] *********************************************************************************************************************************************************************************************
fatal: [lighthouse-01]: FAILED! => {"changed": false, "msg": "Failed to find required executable git in paths: /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin"}
...ignoring

TASK [Lighthouse | Create lighthouse config] **********************************************************************************************************************************************************************************
changed: [lighthouse-01]

RUNNING HANDLER [reload-nginx] ************************************************************************************************************************************************************************************************
skipping: [lighthouse-01]

PLAY [Install Clickhouse] *****************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Clickhouse | Get distrib] ***********************************************************************************************************************************************************************************************
changed: [clickhouse-01] => (item=clickhouse-client)
changed: [clickhouse-01] => (item=clickhouse-server)
changed: [clickhouse-01] => (item=clickhouse-common-static)

TASK [Clickhouse | Install packages] ******************************************************************************************************************************************************************************************
changed: [clickhouse-01]

RUNNING HANDLER [Start clickhouse service] ************************************************************************************************************************************************************************************
fatal: [clickhouse-01]: FAILED! => {"changed": false, "msg": "Could not find the requested service clickhouse-server: host"}
...ignoring

TASK [Clickhouse | Create database] *******************************************************************************************************************************************************************************************
skipping: [clickhouse-01]

PLAY [Install Vector] *********************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [vector-01]

TASK [Vector | Install rpm] ***************************************************************************************************************************************************************************************************
changed: [vector-01]

TASK [Vector | Template config] ***********************************************************************************************************************************************************************************************
changed: [vector-01]

TASK [Vector | Create systemd unit] *******************************************************************************************************************************************************************************************
changed: [vector-01]

TASK [Vector | Start service] *************************************************************************************************************************************************************************************************
fatal: [vector-01]: FAILED! => {"changed": false, "msg": "Could not find the requested service vector: host"}
...ignoring

PLAY RECAP ********************************************************************************************************************************************************************************************************************
clickhouse-01              : ok=4    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=1   
lighthouse-01              : ok=9    changed=4    unreachable=0    failed=0    skipped=2    rescued=0    ignored=2   
vector-01                  : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=1 
```


7.

```shell
root@ubnt2004:~/ansible_dz/ansible-03/playbook# ansible-playbook -i inventory/prod.yml site.yml --diff

PLAY [Install Nginx] **********************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [NGINX | Install epel-release] *******************************************************************************************************************************************************************************************
changed: [lighthouse-01]

TASK [NGINX | Install NGINX] **************************************************************************************************************************************************************************************************
changed: [lighthouse-01]

TASK [NGINX | Create file for lighthouse config] ******************************************************************************************************************************************************************************
--- before
+++ after
@@ -1,6 +1,6 @@
 {
-    "atime": 1683209080.2954264,
-    "mtime": 1683209080.2954264,
+    "atime": 1683209080.299803,
+    "mtime": 1683209080.299803,
     "path": "/etc/nginx/conf.d/lighthouse.conf",
-    "state": "absent"
+    "state": "touch"
 }

changed: [lighthouse-01]

TASK [NGINX | Create general config] ******************************************************************************************************************************************************************************************
--- before: /etc/nginx/nginx.conf
+++ after: /root/ansible_dz/ansible-03/playbook/templates/nginx.conf.j2
@@ -1,84 +1,35 @@
-# For more information on configuration, see:
-#   * Official English Documentation: http://nginx.org/en/docs/
-#   * Official Russian Documentation: http://nginx.org/ru/docs/
-
-user nginx;
-worker_processes auto;
-error_log /var/log/nginx/error.log;
-pid /run/nginx.pid;
-
-# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
-include /usr/share/nginx/modules/*.conf;
+worker_processes  1;
+user              centos;
 
 events {
-    worker_connections 1024;
+    worker_connections  1024;
 }
 
+error_log         /var/log/nginx/error.log info;
+pid               /var/run/nginx.pid;
+
 http {
-    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
-                      '$status $body_bytes_sent "$http_referer" '
-                      '"$http_user_agent" "$http_x_forwarded_for"';
 
-    access_log  /var/log/nginx/access.log  main;
+    include       mime.types;
+    charset       utf-8;
 
-    sendfile            on;
-    tcp_nopush          on;
-    tcp_nodelay         on;
-    keepalive_timeout   65;
-    types_hash_max_size 4096;
-
-    include             /etc/nginx/mime.types;
-    default_type        application/octet-stream;
-
-    # Load modular configuration files from the /etc/nginx/conf.d directory.
-    # See http://nginx.org/en/docs/ngx_core_module.html#include
-    # for more information.
-    include /etc/nginx/conf.d/*.conf;
+    access_log    /var/log/nginx/access.log  combined;
 
     server {
-        listen       80;
-        listen       [::]:80;
-        server_name  _;
-        root         /usr/share/nginx/html;
+        server_name   localhost;
+        listen        80;
 
-        # Load configuration files for the default server block.
-        include /etc/nginx/default.d/*.conf;
 
-        error_page 404 /404.html;
-        location = /404.html {
+        location      / {
+            root      html;
+
         }
 
-        error_page 500 502 503 504 /50x.html;
-        location = /50x.html {
-        }
+        include conf.d/lighthouse.conf;
+
+
     }
 
-# Settings for a TLS enabled server.
-#
-#    server {
-#        listen       443 ssl http2;
-#        listen       [::]:443 ssl http2;
-#        server_name  _;
-#        root         /usr/share/nginx/html;
-#
-#        ssl_certificate "/etc/pki/nginx/server.crt";
-#        ssl_certificate_key "/etc/pki/nginx/private/server.key";
-#        ssl_session_cache shared:SSL:1m;
-#        ssl_session_timeout  10m;
-#        ssl_ciphers HIGH:!aNULL:!MD5;
-#        ssl_prefer_server_ciphers on;
-#
-#        # Load configuration files for the default server block.
-#        include /etc/nginx/default.d/*.conf;
-#
-#        error_page 404 /404.html;
-#            location = /40x.html {
-#        }
-#
-#        error_page 500 502 503 504 /50x.html;
-#            location = /50x.html {
-#        }
-#    }
 
 }
 

changed: [lighthouse-01]

RUNNING HANDLER [start-nginx] *************************************************************************************************************************************************************************************************
changed: [lighthouse-01]

RUNNING HANDLER [reload-nginx] ************************************************************************************************************************************************************************************************
changed: [lighthouse-01]

PLAY [Install LightHouse] *****************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Install dependencies] **************************************************************************************************************************************************************************************
changed: [lighthouse-01]

TASK [Lighthouse | Copy from git] *********************************************************************************************************************************************************************************************
>> Newly checked out d701335c25cd1bb8b5155711190bad8ab852c2ce
changed: [lighthouse-01]

TASK [Lighthouse | Create lighthouse config] **********************************************************************************************************************************************************************************
--- before: /etc/nginx/conf.d/lighthouse.conf
+++ after: /root/ansible_dz/ansible-03/playbook/templates/lighthouse.conf.j2
@@ -0,0 +1,8 @@
+
+        location /lighthouse {
+            root /var/www/lighthouse;
+        }
+
+
+
+

changed: [lighthouse-01]

RUNNING HANDLER [reload-nginx] ************************************************************************************************************************************************************************************************
changed: [lighthouse-01]

PLAY [Install Clickhouse] *****************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Clickhouse | Get distrib] ***********************************************************************************************************************************************************************************************
ok: [clickhouse-01] => (item=clickhouse-client)
ok: [clickhouse-01] => (item=clickhouse-server)
ok: [clickhouse-01] => (item=clickhouse-common-static)

TASK [Clickhouse | Install packages] ******************************************************************************************************************************************************************************************
changed: [clickhouse-01]

RUNNING HANDLER [Start clickhouse service] ************************************************************************************************************************************************************************************
changed: [clickhouse-01]

TASK [Clickhouse | Create database] *******************************************************************************************************************************************************************************************
changed: [clickhouse-01]

PLAY [Install Vector] *********************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [vector-01]

TASK [Vector | Install rpm] ***************************************************************************************************************************************************************************************************
changed: [vector-01]

TASK [Vector | Template config] ***********************************************************************************************************************************************************************************************
--- before
+++ after: /root/ansible_dz/ansible-03/playbook/templates/vector.yaml.j2
@@ -0,0 +1,18 @@
+sinks:
+    to_clickhouse:
+        compression: gzip
+        database: custom
+        endpoint: localhost:8123
+        healthcheck: false
+        inputs:
+        - our_log
+        skip_unknown_fields: true
+        table: my_table
+        type: clickhouse
+sources:
+    our_log:
+        ignore_older_secs: 600
+        include:
+        - /home/centos/logs/*.log
+        read_from: beginning
+        type: file

[WARNING]: The value "1000" (type int) was converted to "u'1000'" (type string). If this does not look like what you expect, quote the entire value to ensure it does not change.
changed: [vector-01]

TASK [Vector | Create systemd unit] *******************************************************************************************************************************************************************************************
--- before
+++ after: /root/ansible_dz/ansible-03/playbook/templates/vector.service.j2
@@ -0,0 +1,26 @@
+#
+# Ansible managed
+#
+[Unit]
+Description=Vector
+Documentation=https://vector.dev/docs/about/what-is-vector/
+Requires=network-online.target
+After=network-online.target
+
+[Service]
+User=root
+Group=root
+
+ExecStart=/usr/bin/vector
+ExecReload=/bin/kill -HUP $MAINPID
+
+StandardOutput=journal
+StandardError=journal
+
+SyslogIdentifier=vector
+
+KillSignal=SIGTERM
+Restart=no
+
+[Install]
+WantedBy=multi-user.target
\ No newline at end of file

changed: [vector-01]

TASK [Vector | Start service] *************************************************************************************************************************************************************************************************
changed: [vector-01]

PLAY RECAP ********************************************************************************************************************************************************************************************************************
clickhouse-01              : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
lighthouse-01              : ok=12   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
vector-01                  : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```


8.

```shell
root@ubnt2004:~/ansible_dz/ansible-03/playbook# ssh centos@158.160.48.236
[centos@vector ~]$ systemctl status vector
● vector.service - Vector
   Loaded: loaded (/etc/systemd/system/vector.service; disabled; vendor preset: disabled)
   Active: active (running) since Пн 2023-05-15 11:22:14 UTC; 43s ago
     Docs: https://vector.dev/docs/about/what-is-vector/
 Main PID: 6181 (vector)
   CGroup: /system.slice/vector.service
           └─6181 /usr/bin/vector
[centos@vector ~]$ exit
logout
Connection to 158.160.48.236 closed.
root@ubnt2004:~/ansible_dz/ansible-03/playbook# ssh centos@158.160.58.80
[centos@clickhouse ~]$ clickhouse-client -h 127.0.0.1
ClickHouse client version 22.3.10.22 (official build).
Connecting to 127.0.0.1:9000 as user default.
Connected to ClickHouse server version 22.3.10 revision 54455.

clickhouse.ru-central1.internal :)
```

lighthouse доступен по веб интерфейсу

Повторный запуск playbook

```shell
root@ubnt2004:~/ansible_dz/ansible-03/playbook# ansible-playbook -i inventory/prod.yml site.yml --diff

PLAY [Install Nginx] **********************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [NGINX | Install epel-release] *******************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [NGINX | Install NGINX] **************************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [NGINX | Create file for lighthouse config] ******************************************************************************************************************************************************************************
--- before
+++ after
@@ -1,6 +1,6 @@
 {
-    "atime": 1683209137.8013527,
-    "mtime": 1683209134.126357,
+    "atime": 1683209407.573454,
+    "mtime": 1683209407.573454,
     "path": "/etc/nginx/conf.d/lighthouse.conf",
-    "state": "file"
+    "state": "touch"
 }

changed: [lighthouse-01]

TASK [NGINX | Create general config] ******************************************************************************************************************************************************************************************
ok: [lighthouse-01]

PLAY [Install LightHouse] *****************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Install dependencies] **************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Copy from git] *********************************************************************************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Create lighthouse config] **********************************************************************************************************************************************************************************
ok: [lighthouse-01]

PLAY [Install Clickhouse] *****************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Clickhouse | Get distrib] ***********************************************************************************************************************************************************************************************
ok: [clickhouse-01] => (item=clickhouse-client)
ok: [clickhouse-01] => (item=clickhouse-server)
ok: [clickhouse-01] => (item=clickhouse-common-static)

TASK [Clickhouse | Install packages] ******************************************************************************************************************************************************************************************
ok: [clickhouse-01]

TASK [Clickhouse | Create database] *******************************************************************************************************************************************************************************************
ok: [clickhouse-01]

PLAY [Install Vector] *********************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************************
ok: [vector-01]

TASK [Vector | Install rpm] ***************************************************************************************************************************************************************************************************
ok: [vector-01]

TASK [Vector | Template config] ***********************************************************************************************************************************************************************************************
[WARNING]: The value "1000" (type int) was converted to "u'1000'" (type string). If this does not look like what you expect, quote the entire value to ensure it does not change.
ok: [vector-01]

TASK [Vector | Create systemd unit] *******************************************************************************************************************************************************************************************
ok: [vector-01]

TASK [Vector | Start service] *************************************************************************************************************************************************************************************************
ok: [vector-01]

PLAY RECAP ********************************************************************************************************************************************************************************************************************
clickhouse-01              : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
lighthouse-01              : ok=9    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
vector-01                  : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```
