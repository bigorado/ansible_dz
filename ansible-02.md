1. Подготовьте свой inventory-файл `prod.yml`.
2. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает [vector](https://vector.dev).
3. При создании tasks рекомендую использовать модули: `get_url`, `template`, `unarchive`, `file`.
4. Tasks должны: скачать дистрибутив нужной версии, выполнить распаковку в выбранную директорию, установить vector.
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
9. Подготовьте README.md-файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-02-playbook` на фиксирующий коммит, в ответ предоставьте ссылку на него.

root@ubnt2004:~/ansible_dz/ansible-02/playbook#

Ответы:

1. Тестовая среда развернута в ЯндексКлауд исходники /testvm

```shell
---
clickhouse:
  hosts:
    clickhouse-01:
      ansible_host: 158.160.58.80
vector:
  hosts:
    vector-01:
      ansible_host: 158.160.48.236
````


4.

```shell
- name: Install and config Vector
  hosts: vector
  handlers:
    - name: Start Vector service
      become: true
      ansible.builtin.service:
        name: vector
        state: restarted
  tasks:
    - name: Add clickhouse addresses to /etc/hosts
      become: true
      lineinfile:
        dest: /etc/hosts
        regexp: '.*{{ item }}$'
        line: "{{ hostvars[item].ansible_host }} {{item}}"
        state: present
      when: hostvars[item].ansible_host is defined
      with_items: "{{ groups.clickhouse }}"
    - name: Get vector distrib
      ansible.builtin.get_url:
        url: "https://packages.timber.io/vector/latest/vector-{{ vector_version }}.x86_64.rpm"
        dest: "./vector-{{ vector_version }}.x86_64.rpm"
    - name: Install vector package
      become: true
      ansible.builtin.yum:
        name:
          - "./vector-{{ vector_version }}.x86_64.rpm"
    - name: Vector config name
      tags: vector_config
      become: true
      ansible.builtin.lineinfile:
        path: /etc/default/vector
        regexp: 'VECTOR_CONFIG='
        line: VECTOR_CONFIG=/etc/vector/config.yaml
    - name: Create vector config
      tags: vector_config
      become: true
      ansible.builtin.copy:
        dest: /etc/vector/config.yaml
        content: |
          {{ vector_config | to_nice_yaml(indent=2) }}

          notify: Start Vector service

```

7.

```shell
root@ubnt2004:~/ansible_dz/ansible-02/playbook# ansible-playbook -i inventory/prod.yml -v site.yml -u centos

PLAY [Install Clickhouse] ********************************************************************************

TASK [Gathering Facts] ***********************************************************************************
ok: [clickhouse-01]

TASK [Get clickhouse distrib (rpm noarch package)] *******************************************************
changed: [clickhouse-01] => (item=clickhouse-client)
changed: [clickhouse-01] => (item=clickhouse-server)
failed: [clickhouse-01] (item=clickhouse-common-static) => {"ansible_loop_var": "item", "changed": false, "dest": "./clickhouse-common-static-22.3.3.44.rpm", "elapsed": 3, "item": "clickhouse-common-static", "msg": "Request failed", "response": "HTTP Error 404: Not Found", "status_code": 404, "url": "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-22.3.3.44.noarch.rpm"}

TASK [Get clickhouse distrib (rpm package)] **************************************************************
changed: [clickhouse-01]

TASK [Install clickhouse packages] ***********************************************************************
changed: [clickhouse-01]

TASK [Flush handlers] ************************************************************************************

RUNNING HANDLER [Start clickhouse service] ***************************************************************
changed: [clickhouse-01]

TASK [Create database] ***********************************************************************************
changed: [clickhouse-01]

PLAY [Install and configure Vector] **********************************************************************

TASK [Gathering Facts] ***********************************************************************************
ok: [vector-01]

TASK [Add clickhouse addresses to /etc/hosts] ************************************************************
changed: [vector-01] => (item=clickhouse-01)

TASK [Get vector distrib] ********************************************************************************
changed: [vector-01]

TASK [Install vector package] ****************************************************************************
changed: [vector-01]

TASK [Vector config name] ***********************************************************************
changed: [vector-01]

TASK [Create vector config] ******************************************************************************
changed: [vector-01]

RUNNING HANDLER [Start Vector service] *******************************************************************
changed: [vector-01]

PLAY RECAP ***********************************************************************************************
clickhouse-01              : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0   
vector-01                  : ok=6    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

8.

```shell
root@ubnt2004:~/ansible_dz/ansible-02/playbook# ansible-playbook -i inventory/prod.yml -v site.yml --diff -u centos

PLAY [Install Clickhouse] ********************************************************************************

TASK [Gathering Facts] ***********************************************************************************
ok: [clickhouse-01]

TASK [Get clickhouse distrib (rpm noarch package)] *******************************************************
ok: [clickhouse-01] => (item=clickhouse-client)
ok: [clickhouse-01] => (item=clickhouse-server)
failed: [clickhouse-01] (item=clickhouse-common-static) => {"ansible_loop_var": "item", "changed": false, "dest": "./clickhouse-common-static-22.3.3.44.rpm", "elapsed": 3, "gid": 1000, "group": "vagrant", "item": "clickhouse-common-static", "mode": "0664", "msg": "Request failed", "owner": "vagrant", "response": "HTTP Error 404: Not Found", "secontext": "unconfined_u:object_r:user_home_t:s0", "size": 246310036, "state": "file", "status_code": 404, "uid": 1000, "url": "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-22.3.3.44.noarch.rpm"}

TASK [Get clickhouse distrib (rpm package)] **************************************************************
ok: [clickhouse-01]

TASK [Install clickhouse packages] ***********************************************************************
ok: [clickhouse-01]

TASK [Flush handlers] ************************************************************************************

TASK [Create database] ***********************************************************************************
ok: [clickhouse-01]

PLAY [Install and configure Vector] **********************************************************************

TASK [Gathering Facts] ***********************************************************************************
ok: [vector-01]

TASK [Add clickhouse addresses to /etc/hosts] ************************************************************
ok: [vector-01] => (item=clickhouse-01)

TASK [Get vector distrib] ********************************************************************************
ok: [vector-01]

TASK [Install vector package] ****************************************************************************
ok: [vector-01]

TASK [Vector config name] ***********************************************************************
ok: [vector-01]

TASK [Create vector config] ******************************************************************************
ok: [vector-01]

PLAY RECAP ***********************************************************************************************
clickhouse-01              : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0   
vector-01                  : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

9.

```shell
---
- name: Install Clickhouse
  hosts: clickhouse
#Блок handler который выполняется после всех таск, рестарт службы
  handlers:
    - name: Start clickhouse service
      become: true
      ansible.builtin.service:
        name: clickhouse-server
        state: restarted
  tasks:
#При выполнении tasks и возникновении ошибок задачи по блоку передаются в rescue, далее в always. Always выполняется всегда.
    - block:
        - name: Get clickhouse distrib
#Получаем дистрибутивы clickhouse из репозитория
          ansible.builtin.get_url:
            url: "https://packages.clickhouse.com/rpm/stable/{{ item }}-{{ clickhouse_version }}.noarch.rpm"
#Указываем расположение пакета и даем названия
            dest: "./{{ item }}-{{ clickhouse_version }}.rpm"
#Получаем исполняемые файлы, клиентские и серверные указанные в переменных groups_vars/clickhouse/vars.yml
          with_items: "{{ clickhouse_packages }}"
#Если в верхней части блока были ошибки, подбираем подходящие пакеты
      rescue:
        - name: Get clickhouse distrib
          ansible.builtin.get_url:
            url: "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-{{ clickhouse_version }}.x86_64.rpm"
            dest: "./clickhouse-common-static-{{ clickhouse_version }}.rpm"
      always:
        - name: Install clickhouse packages
          become: true
#Производим установку скачанных пакетов
          ansible.builtin.yum:
            name:
              - clickhouse-common-static-{{ clickhouse_version }}.rpm
              - clickhouse-client-{{ clickhouse_version }}.rpm
              - clickhouse-server-{{ clickhouse_version }}.rpm
#Запускаем handler
          notify: Start clickhouse service
#Информируем о выполнении handler
        - name: Flush handlers
          meta: flush_handlers
#Создаем БД clickhouse
        - name: Create database
          ansible.builtin.command: "clickhouse-client -q 'create database logs;'"
          register: create_db
          failed_when: create_db.rc != 0 and create_db.rc !=82
          changed_when: create_db.rc == 0
- name: Install and config Vector
  hosts: vector
#Блок хэндлера который выполняется после всех таск, рестарт службы
  handlers:
    - name: Start Vector service
      become: true
      ansible.builtin.service:
        name: vector
        state: restarted
  tasks:
#Прописываем в hosts ip серверов
    - name: Add clickhouse addresses to /etc/hosts
      become: true
      lineinfile:
        dest: /etc/hosts
        regexp: '.*{{ item }}$'
        line: "{{ hostvars[item].ansible_host }} {{item}}"
        state: present
      when: hostvars[item].ansible_host is defined
      with_items: "{{ groups.clickhouse }}"
    - name: Get vector distrib
#Получаем исполняемые файлы, клиентские и серверные указанные в переменных groups_vars/vector/vars.yml
      ansible.builtin.get_url:
        url: "https://packages.timber.io/vector/latest/vector-{{ vector_version }}.x86_64.rpm"
        dest: "./vector-{{ vector_version }}.x86_64.rpm"
    - name: Install vector package
      become: true
#Устанавливаем vector
      ansible.builtin.yum:
        name:
          - "./vector-{{ vector_version }}.x86_64.rpm"
    - name: Vector config name
      tags: vector_config
      become: true
      ansible.builtin.lineinfile:
        path: /etc/default/vector
        regexp: 'VECTOR_CONFIG='
        line: VECTOR_CONFIG=/etc/vector/config.yaml
#Правим конфигурацию из указанной в переменной groups_vars/vector/vars.yml
    - name: Create vector config
      tags: vector_config
      become: true
      ansible.builtin.copy:
        dest: /etc/vector/config.yaml
        content: |
          {{ vector_config | to_nice_yaml(indent=2) }}

          notify: Start Vector service

```
