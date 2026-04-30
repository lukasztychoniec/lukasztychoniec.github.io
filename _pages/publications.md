---
title: "Publications"
layout: gridlay
sitemap: false
permalink: /publications/
---

## Publications

<input type="text" class="pub-search" id="pubSearch" placeholder="Filter by title, author, or year...">

<div class="section-card" id="pubList">
<!---
<h3>Preprints</h3>
{% bibliography --query @unpublished %}
-->

<h3>Refereed first-author articles</h3>

{% filtered_bibliography firstauthor %}

<!---

<h3>Refereed Conference Proceedings</h3>

{% bibliography --query @inproceedings %}
-->

<h3> Refereed co-authored Articles with key contribution</h3>
{% filtered_bibliography keyauthor %}

</div>
