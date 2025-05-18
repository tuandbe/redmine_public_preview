$(document).ready(function() {
  console.log('Subtask creator script loaded');
  
  // Add event listener for the subtask creator button
  $(document).on('click', '.subtask-creator-button', function(e) {
    // Log to confirm click is detected
    console.log('Subtask creator button clicked');
    
    // The necessary data is stored in data attributes of the button
    var button = $(this);
    
    // Debug data attributes
    Object.keys(button.data()).forEach(function(key) {
      console.log('Data attribute: ' + key + ' = ' + button.data(key));
    });
    
    var parentId = button.attr('data-parent-id');
    var briefFieldId = button.attr('data-brief-field-id');
    var designerFieldId = button.attr('data-designer-field-id');
    var designDateFieldId = button.attr('data-design-date-field-id');
    
    // Get values directly from the page instead of relying on API
    var briefValue = button.attr('data-brief-value') || '';
    var designerValue = button.attr('data-designer-value') || '';
    var designDateValue = button.attr('data-design-date-value') || '';
    var parentSubject = button.attr('data-parent-subject') || '';
    
    console.log('From attr - Parent ID:', parentId);
    console.log('From attr - Brief Value:', briefValue);
    console.log('From attr - Designer Value:', designerValue);
    console.log('From attr - Design Date Value:', designDateValue);
    console.log('From attr - Parent Subject:', parentSubject);
    
    // Store the values in localStorage so they can be accessed on the new issue form
    // and persisted across page loads
    localStorage.setItem('subtask_parent_id', parentId);
    localStorage.setItem('subtask_brief_value', briefValue);
    localStorage.setItem('subtask_designer_value', designerValue);
    localStorage.setItem('subtask_design_date_value', designDateValue);
    localStorage.setItem('subtask_parent_subject', parentSubject);
    localStorage.setItem('subtask_creation_time', new Date().getTime());
    
    console.log('Stored values in localStorage');
  });
  
  // Check if we're on the new issue form page with stored values
  if (window.location.pathname.includes('/issues/new')) {
    console.log('On new issue form page');
    
    var parentId = localStorage.getItem('subtask_parent_id');
    var briefValue = localStorage.getItem('subtask_brief_value');
    var designerValue = localStorage.getItem('subtask_designer_value');
    var designDateValue = localStorage.getItem('subtask_design_date_value');
    var parentSubject = localStorage.getItem('subtask_parent_subject');
    var creationTime = localStorage.getItem('subtask_creation_time');
    
    // Only process if data is recent (less than 5 minutes old)
    var isRecent = creationTime && (new Date().getTime() - creationTime < 5 * 60 * 1000);
    
    console.log('Retrieved from storage - Parent ID:', parentId);
    console.log('Retrieved from storage - Brief Value:', briefValue);
    console.log('Retrieved from storage - Designer Value:', designerValue);
    console.log('Retrieved from storage - Design Date Value:', designDateValue);
    console.log('Retrieved from storage - Parent Subject:', parentSubject);
    console.log('Data timestamp:', creationTime, 'Is recent:', isRecent);
    
    if (!parentId || !isRecent) {
      console.log('No recent parent ID found in storage or data is too old');
      return;
    }
    
    // Verify that this is intended to be a subtask of the stored parent
    var parentIdFromUrl = new URLSearchParams(window.location.search).get('issue[parent_issue_id]');
    if (parentIdFromUrl !== parentId) {
      console.log('Parent ID in URL does not match stored parent ID, not a subtask creation flow');
      return;
    }
    
    console.log('Starting to apply stored values to form');
    
    // Set the subject with the order prefix and parent subject
    if (parentSubject) {
      var subjectField = $('#issue_subject');
      if (subjectField.val() === '' || subjectField.val().indexOf('[Order Ảnh]') === 0) {
        subjectField.val('[Order Ảnh] - ' + parentSubject);
        console.log('Set subject to: [Order Ảnh] - ' + parentSubject);
      }
    }
    
    // Set the description to the brief value
    if (briefValue && briefValue !== '') {
      var descriptionField = $('#issue_description');
      if (descriptionField.val() === '') {
        descriptionField.val(briefValue);
        console.log('Set description to:', briefValue);
      }
    }
    
    // Set the designer as the assignee if available
    if (designerValue && designerValue !== '') {
      // Try to find the user in the assignee dropdown
      var assigneeSelect = $('#issue_assigned_to_id');
      console.log('Looking for designer:', designerValue, 'in dropdown options:');
      
      var found = false;
      assigneeSelect.find('option').each(function() {
        console.log('Option:', $(this).text().trim(), $(this).val());
        if ($(this).text().trim() === designerValue) {
          assigneeSelect.val($(this).val());
          found = true;
          console.log('Set assignee to:', designerValue);
          return false;
        }
      });
      
      if (!found) {
        console.warn('Could not find matching assignee for:', designerValue);
      }
    }
    
    // Set the due date if available
    if (designDateValue && designDateValue !== '') {
      $('#issue_due_date').val(designDateValue);
      console.log('Set due date to:', designDateValue);
    }
    
    // Clear the localStorage to avoid interfering with future forms
    localStorage.removeItem('subtask_parent_id');
    localStorage.removeItem('subtask_brief_value');
    localStorage.removeItem('subtask_designer_value');
    localStorage.removeItem('subtask_design_date_value');
    localStorage.removeItem('subtask_parent_subject');
    localStorage.removeItem('subtask_creation_time');
    console.log('Cleared localStorage');
  }
}); 
