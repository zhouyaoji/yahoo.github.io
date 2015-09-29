---
layout: yahoo
title: Git Stats
categories: [git, yahoo, stats]
tags: [open source, git, repo, stats]
---
<div class="center">
<h1 align="center">Yahoo Git Stats</h1>

<span style="font-style: italic; font-size: 12px; text-align: left">Last modified on {{ site.data.defaults.stat_src | file_date | date: "%D" }} at 
{{ site.data.defaults.stat_src | file_date | date: "%T" }}.</span>

<table class="pure-table pure-table-horizontal sortable">
<thead>
<tr align="left">
{% for header in site.data.defaults.headers %}
<th>{{ header | tooltip }}</th>
{% endfor %}
</tr>
</thead>
{% for repo in site.data.sorted_public_yahoo_git %}
    <tr>
  <td>
    <a href="{{ repo.repository_url }}">
      {{ repo.repository_name }}
    </a>
   </td>
   <td>
    {{ repo.watchers_count }}
   </td>
   <td>
    {{ repo.forks_count }}
   </td>
   <td>
    {{ repo.open_issues_count }}
   </td>
   <td>
    <span style='font-weight:500'>Date:</span> {{ repo.last_update | date: "%F" }}<br/> 
    <span style='font-weight:500'>Time:</span> {{ repo.last_update | date: "%X" }}
   </td>
   <td>
    {% if repo.language %}
      {{ repo.language }}
     {% else %}
       Unknown
     {% endif %}
   </td>
   </tr>
{% endfor %}
</table>
</div>
