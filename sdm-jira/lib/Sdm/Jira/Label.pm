
package Sdm::Jira::Label;

class Sdm::Jira::Label {
    table_name => 'label',
    schema_name => 'Jira',
    data_source => 'Sdm::DataSource::Jira',
    id_by => [
        id => { is => 'Number' },
    ],
    has => [
        fieldid   => { is => 'Number' },
        issue_id     => { is => 'Number', column_name => 'issue' },
        label     => { is => 'Text' },
        issue => { is => 'Sdm::Jira::Issue', id_by => 'issue_id' },
    ]
};

1;
