{%- from "dovecot/map.jinja" import dovecot with context -%}

{%- set virtual_users = salt['pillar.get']('dovecot:virtual_users', {}) -%}

virtual-users-db-dir:
  file.directory:
    - name: {{ dovecot.virtual_user_db_dir }}

virtual-users-db:
  sqlite3.table_present:
    - db: {{ dovecot.virtual_user_db_dir }}/{{ dovecot.virtual_user_db_file }}
    - name: users
    - schema:
      - username VARCHAR(128) NOT NULL
      - domain VARCHAR(128) NOT NULL
      - password VARCHAR(64) NOT NULL
      - active CHAR(1) DEFAULT 'Y' NOT NULL
    - require:
      - file: virtual-users-db-dir

{% for domain, users in virtual_users|dictsort %}
{%- for username, password in users|dictsort %}
virtual-users-user-{{ domain }}-{{ username }}:
  sqlite3.row_present:
    - db: {{ dovecot.virtual_user_db_dir }}/{{ dovecot.virtual_user_db_file }}
    - table: users
    - data:
        username: {{ username }}
        domain: {{ domain }}
        password: '{{ password }}'
        active: Y
    - where_sql: 'username=? AND domain=?'
    - where_args:
      - {{ username }}
      - {{ domain }}
    - update: True
    - require:
      - sqlite3: virtual-users-db
{% endfor %}
{%- endfor %}
