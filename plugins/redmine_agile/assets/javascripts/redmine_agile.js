(function() {
  var AgileBoard = function() {};

  AgileBoard.prototype = {

    init: function(routes) {
      var self = this;
      self.routes = routes;

      $(function() {
        self.initSortable();
        self.initDraggable();
        self.initDroppable();
        self.initLoadMoreLinks();
      });
    },

    successSortable: function($oldColumn, $column) {
      var r = new RegExp(/\d+/)
      var ids = [];

      ids.push({
        column: $column,
        id: $column.data('id'),
        to: true
      });
      ids.push({
        column: $oldColumn,
        id: $oldColumn.data('id'),
        from: true
      });

      for (var i = 0; i < ids.length; i++) {
        var current = ids[i];
        var headerSelector = '.issues-board thead tr th[data-column-id="' + current.id + '"]';
        var $columnHeader = $(headerSelector);
        var columnText = $columnHeader.text();
        var currentIssuesAmount = ~~columnText.match(r);
        currentIssuesAmount = (current.from) ? currentIssuesAmount - 1 : currentIssuesAmount + 1;
        $columnHeader.text(columnText.replace(r, currentIssuesAmount));
      }
    },

    errorSortable: function($oldColumn, responseText) {
      var errors = JSON.parse(responseText);
      var alertMessage = '';

      $oldColumn.sortable('cancel');

      if (errors && errors.length > 0) {
        for (var i = 0; i < errors.length; i++) {
          alertMessage += errors[i] + '\n';
        }
      }
      alert(alertMessage);
    },

    initSortable: function() {
      var self = this;
      var $issuesCols = $(".issue-status-col");

      $issuesCols.sortable({
        connectWith: ".issue-status-col",
        start: function(event, ui) {
          var $item = $(ui.item);
          $item.attr('oldColumnId', $item.parent().data('id'));
        },
        stop: function(event, ui) {
          var $item = $(ui.item);
          var sender = ui.sender;
          var $column = $item.parents('.issue-status-col');
          var issue_id = $item.data('id');
          var status_id = $column.data("id");
          var order = $column.sortable('serialize');
          var positions = {};
          var oldId = $item.attr('oldColumnId');
          var $oldColumn = $('.ui-sortable[data-id="' + oldId + '"]');

          $column.find('.issue-card').each(function(i, e) {
            var $e = $(e);
            positions[$e.data('id')] = { position: $e.index() };
          });

          $.ajax({
            url: self.routes.update_agile_board_path,
            dataType: "json",
            type: 'PUT',
            data: {
              issue: {
                status_id: status_id
              },
              positions: positions,
              id: issue_id
            },
            success: function(data, status, xhr) {
              self.successSortable($oldColumn, $column);
            },
            error: function(xhr, status, error) {
              self.errorSortable($oldColumn, xhr.responseText);
            }
          });
        }
      }).disableSelection();

      $issuesCols.sortable( "option", "cancel", "a.load-more-issues" );
    },

    initDraggable: function() {
      $(".assignable-user").draggable({
        helper: "clone",
        start: function startDraggable(event, ui) {
          $(ui.helper).addClass("draggable-active")
        }
      });
    },
    
    initDroppable: function() {
      var self = this;

      $(".issue-card").droppable({
        activeClass: 'droppable-active',
        hoverClass: 'droppable-hover',
        accept: '.assignable-user',
        tolerance: 'pointer',
        drop: function(event, ui) {
          var $self = $(this);

          $.ajax({
            url: self.routes.issues_path + '/' + $self.data("id"),
            type: "PUT",
            dataType: "json",
            data: {
              issue: {
                assigned_to_id: ui.draggable.data("id")
              }
            }
          });
          $self.find("p.info").show();
          $self.find("p.info").html(ui.draggable.clone());
        }
      });
    },

    issuesLoadedSuccessfully: function($currentColumn, $wrapper, r) {
      var $loadedIssues = $currentColumn.find('.issue-card');
      var lastIssue = $loadedIssues.last();
      var headerSelector = '.issues-board thead tr th[data-column-id="' + $currentColumn.data('id') + '"]';
      var totalIssues = ~~$(headerSelector).text().match(r);
      if ($loadedIssues.length >= totalIssues) {
        $wrapper.remove();
      } else {
        $wrapper.insertAfter(lastIssue);
      }
    },

    initLoadMoreLinks: function() {
      var self = this;

      $('.load-more-issues').click(function(event) {
        event.preventDefault();
        var r = new RegExp(/\d+/);
        var $target = $(event.target);
        var statusId = ~~$target.attr("id").match(r);
        var $wrapper = $target.parent()
        var $currentColumn = $target.parents('.issue-status-col');
        var offset = $currentColumn.find('.issue-card').length;
        $.ajax({
          url: self.routes.load_more_issues,
          type: "GET",
          data: {
            status_id: statusId,
            offset: offset,
            column_id: $currentColumn.data('id')
          },
          success: function(data, status, xhr) {
            self.issuesLoadedSuccessfully($currentColumn, $wrapper, r);
          }
        });
      });
    }
  }

  window.AgileBoard = AgileBoard;
})();