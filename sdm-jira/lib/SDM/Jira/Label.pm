
package SDM::Jira::Label;

class SDM::Jira::Label {
    table_name => 'label',
    schema_name => 'Jira',
    data_source => 'SDM::DataSource::Jira',
    id_by => [
        id => { is => 'Number' },
    ],
    has => [
        fieldid   => { is => 'Number' },
        issue_id     => { is => 'Number', column_name => 'issue' },
        label     => { is => 'Text' },
        issue => { is => 'SDM::Jira::Issue', id_by => 'issue_id' },
    ]
};

1;
