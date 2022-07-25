# This salt state installs the Nessus Agent using the provided
# URL to the rpm source file.
#
#################################################################
{%- from tpldir ~ '/map.jinja' import nessus with context %}

{%- for log_file,log_rotation in nessus.log_config.items() %}
  {%- for rotation_param,rotation_value in log_rotation.items() %}
Add Log Config {{ log_file }} {{ rotation_param }}:
  file.replace:
    - name: /opt/nessus_agent/var/nessus/log.json
    - pattern: '"file": "{{ log_file }}"'
    - repl: '"{{ rotation_param }}": "{{ rotation_value }}",\n                \g<0>'
    - watch:
      - pkg: Install Nessus Package
  {%- endfor %}
{%- endfor %}

Create Sym-link To Log Dir:
  file.symlink:
    - name: /opt/nessus_agent/var/nessus/logs
    - target: /var/log/nessus/logs
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: True
    - require:
      - file: Pre-Create Nessus Log Directory

Download Nessus Package:
  cmd.run:
    - name: curl -o {{ nessus.package_file }} -L {{ nessus.package_url }}
    - creates: {{ nessus.package_file }}
    - skip_verify: True

Install Nessus Package:
  pkg.installed:
    - sources:
      - {{ nessus.package }}: {{ nessus.package_file }}
    - require:
      - file: Create Sym-link To Log Dir
      - cmd: Download Nessus Package
    - skip_verify: True

Pre-Create Nessus Log Directory:
  file.directory:
    - name: /var/log/nessus/logs
    - user: root
    - group: root
    - dir_mode: '0755'
    - recurse:
      - user
      - group
      - mode
    - makedirs: True
