
package Sdm::Jira::Issue;

class Sdm::Jira::Issue {
    table_name => 'jiraissue',
    schema_name => 'Jira',
    data_source => 'Sdm::DataSource::Jira',
    id_by => [
        id => { is => 'Number' },
    ],
    has => [
        pkey => { is => 'Text' },
        project => { is => 'Number' },
        reporter => { is => 'Text' },
        assignee => { is => 'Text' },
        issuetype => { is => 'Text' },
        summary => { is => 'Text' },
        description => { is => 'Text' },
        environment => { is => 'Text' },
        priority => { is => 'Text' },
        resolution => { is => 'Text' },
        issuestatus => { is => 'Text' },
        created => { is => 'Date' },
        updated => { is => 'Date' },
        duedate => { is => 'Date' },
        resolutiondate => { is => 'Date' },
        votes => { is => 'Number' },
        timeoriginalestimate => { is => 'Number' },
        timeestimate => { is => 'Number' },
        timespent => { is => 'Number' },
        workflow_id => { is => 'Number' },
        security => { is => 'Number' },
        fixfor => { is => 'Number' },
        component => { is => 'Number' },
        issuestatus_obj => { is => 'Sdm::Jira::Issuestatus', id_by => 'issuestatus' },
        status => { is => 'Text', via => 'issuestatus_obj', to => 'pname' },
    ],
    has_many_optional => [
        label_obj => {
            is => 'Sdm::Jira::Label', reverse_as => 'issue'
        },
        label => {
            is => 'Text', via => 'label_obj', to => 'label'
        },
    ]
};

1;
