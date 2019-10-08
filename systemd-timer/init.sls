{%- set config_dir = '/etc/systemd/system' %}

{%- for timer,config in salt['pillar.get']('systemd-timer',{}).items() %}
systemd_timer_{{timer}}_timer:
 file.managed:
   - name: {{config_dir}}/{{timer}}.timer
   - contents: |
         [Unit]
         Description={{ config['Description'] }} Timer

         [Timer]
         {%- for line in config['Timer'] %}
         {{line}}
         {%- endfor %}

         [Install]
         WantedBy=timers.target
   - require_in:
     - service: systemd_timer_{{timer}}_enable

systemd_timer_{{timer}}_service:
  file.managed:
    - name: {{config_dir}}/{{timer}}.service
    - contents: |
          [Unit]
          Description={{ config['Description'] }} Service

          [Service]
          {%- for line in config['Service'] %}
          {%- if line is mapping %}
          {%- set key,items = line.items()|first %}
          {{key}}={{config_dir}}/{{items.get('name')}}
          {%- else %}
          {{line}}
          {%- endif %}
          {%- endfor %}
    - require_in:
      - service: systemd_timer_{{timer}}_enable

{%- for line in config['Service'] %}
{%- if line is mapping %}
{%- set key,items = line.items()|first %}
systemd_timer_{{items.get('name')}}:
  file.managed:
    - name: {{config_dir}}/{{items.get('name')}}
    - mode: 700
    {%- if items.get('source') != None %}
    - source: {{items.get('source')}}
    {%- elif items.get('contents_pillar') != None %}
    - contents_pillar: {{items.get('contents_pillar')}}
    {%- endif %}
{%- endif %}
{%- endfor %}

systemd_timer_{{timer}}_enable:
  service.running:
    - name: {{timer}}.timer
    - enable: true
    - watch:
      - file: systemd_timer_{{timer}}_timer
      - file: systemd_timer_{{timer}}_service
{%- endfor %}
