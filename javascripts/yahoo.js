jQuery(function($){
  (function ( app, undefined ) {

    var yahoo = {
      browserProperties: {
        touch: Modernizr.touch
      },
      $body: $('body'),
      $repoContainer: $('#repos'),
      $filterContainer: $('#filters'),

      init : function() {
        var o = this;
        o.processRepos(publicRepos);
      },

      /*
      getMembers: function() {
        var o = this,
            uri = 'https://api.github.com/orgs/yahoo/members?callback=?';

        $.getJSON(uri, function(result) {
          if (result.meta.status == 403) {
            // Rate limit!
            return;
          }

          o.addRepos(result.data);
        });
      },
      */

      processRepos: function(repos) {
        var o = this;
        languages = o.addRepos(repos);
        o.addFilters(repos, languages);
      },

      addRepos: function(repos) {
        var o = this,
            items = [],
            languages = {},
            source = $('#repo_template').html(),
            template = Handlebars.compile(source);

        $.each(repos, function(i, repo) {

          langClass = null;
          if (repo.language) {
            langClass = repo.language
                          .replace(/#/g, "sharp")
                          .replace(/\+/g, "plus")
                          .replace(/\s+/g, "-")
                          .toLowerCase();

            if (languages[langClass]) {
              languages[langClass]++;
            } else {
              languages[langClass] = 1;
            }
          }

          item = {
            url: repo.html_url,
            name: repo.name,
            language: repo.language,
            languageClass: langClass,
            description: repo.description,
            stars: repo.stargazers_count ? repo.stargazers_count : 0,
            forks: repo.forks_count ? repo.forks_count : 0,
            avatar: null,
            homepage: repo.homepage
          };

          items.push(item);
        });

        // Order repos by stars
        items.sort(function(a,b) {
          if (a.stars < b.stars) return 1;
          if (a.stars > b.stars) return -1;
          return 0;
        });

        // Populate repos
        templateData = { items: items };
        console.log(o.$repoContainer);
        o.$repoContainer.append(template(templateData));

        return languages;
      },

      addFilters: function(repos, languages) {
        var o = this,
            source = $('#buttons_template').html(),
            template = Handlebars.compile(source);

        // Order languages by popularity and clip to top 4
        popularLangs = [];
        $.each(languages, function(lang, qty) {
          popularLangs.push(lang);
        });

        popularLangs.sort(function(a,b) {
          popA = languages[a];
          popB = languages[b];
          if (popA < popB) return 1;
          if (popA > popB) return -1;
          return 0;
        });

        if (3 >= popularLangs.length) {
          popularLangs = popularLangs.slice(0, popularLangs.length);
        } else {
          popularLangs = popularLangs.slice(0, 4);
        }

        buttonItems = [];
        $.each(popularLangs, function(index, name) {
          buttonItems.push( {"name": name} );
        });

        // Populate language filters
        templateData = {
          buttons: buttonItems,
          popular: '.' + popularLangs.join(", .")
        };
        o.$filterContainer.append(template(templateData));

        var filterButtons = $('#filters button');
        filterButtons.on( 'click', function() {
          filterButtons.removeClass('active-filter');
          $(this).addClass('active-filter');

          var filterValue = $(this).attr('data-filter');
          o.$repoContainer.isotope({ filter: filterValue });
        });
      }
    };
    $.extend(app, yahoo);

  }( window.YAHOO = window.YAHOO || {} ));
  YAHOO.init();
});

