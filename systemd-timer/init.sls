{%- set config_dir = '/etc/systemd/system' %}

{%- for timer,config in salt['pillar.get']('systemd-timer',{}).items() %}
systemd_timer_{{timer}}_timer:
 file.managed:
   - name: {{config_dir}}/{{timer}}.timer
   - contents: |
         [Unit]
         Description={{ config['Description'] }} Timer

         [Timer]
         {%- for key,value in config['Timer'].items() %}
         {{key}}={{value}}
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
          {%- for key,value in config['Service'].items() %}
          {%- if value is mapping %}
          {{key}}={{config_dir}}/{{value.name}}
          {%- else %}
          {{key}}={{value}}
          {%- endif %}
          {%- endfor %}
    - require_in:
      - service: systemd_timer_{{timer}}_enable

{%- for key,value in config['Service'].items() %}
{%- if value is mapping %}
systemd_timer_{{value.name}}:
  file.managed:
    - name: {{config_dir}}/{{value.name}}
    - mode: 700
    {%- if value.source is defined %}
    - source: {{value.source}}
    {%- elif value.contents_pillar is defined %}
    - contents_pillar: {{value.contents_pillar}}
    {%- elif value.contents is defined %}
    - contents_pillar: systemd-timer:{{timer}}:Service:{{key}}:contents
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
