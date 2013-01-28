﻿<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>

<!doctype html>
<title>Q42 Continuous Integration</title>

<meta name="apple-touch-fullscreen" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="viewport" content="user-scalable=no,initial-scale=1.0">

<link rel="apple-touch-icon" href="images/q42.png">
<link rel="stylesheet" href="css/styles.css">

<script src="scripts/jquery.min.js"></script>
<script src="scripts/jquery.crypt.js"></script>
<script src="scripts/jquery.timeago.js"></script>
<script src="scripts/jquery.masonry.min.js"></script>
<script src="scripts/metro-grid.js"></script>

<script>
    var lastStr = '';

    function loadData(layout) {
        $.getJSON("data").done(function (data) {
            // // Random bugs!
            // var p = data[Math.floor(Math.random() * data.length)];
            // console.log(p);
            // p.BuildConfigs[Math.floor(Math.random() * p.BuildConfigs.length)].CurrentBuildIsSuccesfull = false;

            var str = JSON.stringify(data);
            if (str == lastStr) return; // nothing changed
            lastStr = str;

            var $buildConfigsContainer = $('#projectsContainer');
            //cleanup old stuff
            $buildConfigsContainer.find('.item').remove();

            $.each(data, function (_, project) {
                var name = project.Name;

                var $a = $('<a href="' + project.Url + '" id=' + project.Id + ' class="item">');

                var $text = $('<div class="item-text">');
                var $extraText = $('<div class=extra-text>');
                $a.append($text);

                var failingSteps = project.BuildConfigs.filter(function (s) { return !s.CurrentBuildIsSuccesfull });
                if (failingSteps.length) {
                    $a.addClass('failing');
                    $text.append('<p><span class=large>' + name + '</p>');

                    var allBreakers = [];

                    $.each(failingSteps, function (_, step) {
                        $text.append('<p id=' + step.Id + ' class=small>'
                                     + '<a href="' + step.Url + '">' + step.Name + '</a></p>');

                        var $breakers = $('<div class=item-images>');
                        var breakers = step.PossibleBuildBreakerEmailAddresses;
                        $.each(breakers, function (_, email) {
                            var emailHash = $().crypt({ method: 'md5', source: email });
                            var url = 'http://www.gravatar.com/avatar/' + emailHash + '?s=500';

                            if (allBreakers.indexOf(email) >= 0) return;
                            allBreakers.push(email);

                            $breakers
                              .append('<img src=' + url + ' class='
                                     + (failingSteps.length > 1 || breakers.length > 1 ? 'half-size' : 'full-size')
                                     + ' alt="' + email + '" title="' + email + '">');
                        })
                        if (breakers.length % 2 == 1 && breakers.length > 1)
                            $breakers
                              .append('<img src=images/transparent.gif class=half-size>');

                        //put the breaking peope images on top inside the project element if there are any
                        if(breakers.length > 0)
                            $a.prepend($breakers);
                    });
                }
                else {
                    $a.addClass('successful')
                    $text.append('<p class=large>' + name + '</p>');

                    if (project.Statistics != null) {
                        $a.append($extraText);//we have extra info to animate

                        //add statistics to animation
                        $text.append(
                            '<div class="statistics-container">' +
                            '<p class="small"><span class="statistic LinesOfCode">Lines of code <span class="value">' + project.Statistics.NonCommentingLinesOfCode + '</span></span></p>' +
                            '<p class="small"><span class="statistic CodeCoveragePercentage">Test coverage <span class="value">' + project.Statistics.CodeCoveragePercentage + '%</span></span></p>' +
                            '</div>'
                            );

                        $extraText.append('<div class="statistic PercentageComments">Comments <span class="value">' + project.Statistics.CommentLinesPercentage + '%</span></div>');
                        $extraText.append('<div class="statistic AmountOfUnitTests">Amount of unit Tests <span class="value">' + project.Statistics.AmountOfUnitTests + '</span></div>');
                        $extraText.append('<div class="statistic CyclomaticComplexityClass">Average class complexity <span class="value">' + project.Statistics.CyclomaticComplexityClass + '</span></div>');
                        $extraText.append('<div class="statistic CyclomaticComplexityFunction">Average func complexity <span class="value">' + project.Statistics.CyclomaticComplexityFunction + '</span></div>');
                    }
                    else {
                        //append buildstep information to animation + summary
                        var buildDate = new Date(parseInt(project.LastBuildDate.substr(6)));
                        $text.append('<p class="small last-build-date"><em>' + $.timeago(buildDate.toISOString()) + '</em></p>');
                    }

                }

                //last part - add icon if available
                if (project.IconUrl != null) {
                    $text.append('<img src="' + project.IconUrl + '" class="logo" />');
                }

                //now append the project to the correct column
                $buildConfigsContainer.append($a);

                //now try if it can be smaller - depends on being attached to the DOM
                if ($a.hasClass('successful')) {
                    $a.width(120);
                    var overflows = $a.find('.item-text p')[0].scrollWidth > $a.find('.item-text p')[0].clientWidth;

                    var wontFit = overflows ||
                      $a.find('.item-text .statistics-container').length ||
                      ($a.find('.item-text .small').position().top > 50 && $a.find('.item-text .logo').length);
                    if (wontFit) {
                        $a.width(250);
                    }
                }
            });

            layout();
        });
        window.setTimeout(loadData.bind(this, layout), 10 * 1000);
    };

    function loadEvents(layout) {
        $.getJSON("pushevents").done(function (data) {
            var $eventsContainer = $('#pushMessagesContainer');
            var $currentEvents = $eventsContainer.find('.event');
            //TODO remove this when real animation is done.

            var fadeOuts = [];

            var newTotal = data.length + $currentEvents.length;

            // fadeout all items which are the oldest and surplus of 5 (when adding the new items)
            for (var i = 0; (newTotal - i) > 5 && i < $currentEvents.length ; i++) {
                (function () {
                    var $evt = $($currentEvents[i]);
                    var evtFadeOutDfd = $.Deferred();
                    fadeOuts.push(evtFadeOutDfd);

                    $evt.fadeOut(400, function () {
                        this.remove();
                        //console.log("removed one");
                        evtFadeOutDfd.resolve();
                    });
                }());
            }

            $.when.apply($, fadeOuts).then(function () {
                //console.log("going to start fadeins");
                $.each(data, function (idx, pushEvent) {
                    //the array of new items is new=>old so we only need the first 5 elements at max
                    if (idx > 4) return false;//more then enough elements

                    //create new element
                    var $a = $('<a href="#" id="" class="item event">');
                    //$a.hide();
                    var $text = $('<div class="item-text">');
                    $a.append($text);
                    var created = new Date(parseInt(pushEvent.Created.substr(6)));
                    var formatted = "" + (created.getHours() < 10 ? "0" + created.getHours() : "" + created.getHours());
                    formatted += ':' + (created.getMinutes() < 10 ? "0" + created.getMinutes() : "" + created.getMinutes());

                    $text.append('<p class=large>' + formatted + ' - ' + pushEvent.RepositoryName + '</p>');
                    $text.append('<div class="event-info"><p class="small">' + pushEvent.ActorUsername + ' pushed ' + pushEvent.AmountOfCommits + ' commits to branch <em>' + pushEvent.BranchName + '</em></p></div>');
                    $text.append('<img src="http://www.gravatar.com/avatar/' + pushEvent.ActorGravatarId + '?s=500" class="pusher"/>');

                    //simple animation
                    $a.fadeOut(0, function () {
                        $eventsContainer.append($a);
                        $a.fadeIn(700, function () {
                        });
                    });
                });
                //layout();
            });

        });
        window.setTimeout(loadEvents.bind(this, layout), 10 * 1000);
    }
</script>

<div id="title">
  <h1>Q42 Continuous Integration</h1>
</div>

<div id="projectsContainer">
</div>


<div id="pushMessagesContainer">
    <h2>Pushes to GitHub</h2>
</div>

<script>
    //window.grid = new MetroGrid();
    //grid.init($('.grid'));

    loadData(function () {
        var $container = $('#projectsContainer');
        $container.imagesLoaded(function () {
            $container.masonry({
                itemSelector: '.item',
                gutterWidth: 10,
                columnWidth: 120,
                isResizable: true,
                isAnimated: true
            });
        });

        //grid.layout();
        //grid.animate();
    });

    loadEvents(function () {
        //we do not use masonry on the push events for now
        //var $container = $('#pushMessagesContainer');
        //$container.imagesLoaded(function () {
        //    $container.masonry({
        //        itemSelector: '.item',
        //        gutterWidth: 10,
        //        columnWidth: 120,
        //        isResizable: true
        //    });
        //});
    });

    //loadData(function () {
    //    grid.layout();
    //    grid.animate();
    //});
    //loadEvents(function () {
    //   grid.layout();
    //});
</script>
