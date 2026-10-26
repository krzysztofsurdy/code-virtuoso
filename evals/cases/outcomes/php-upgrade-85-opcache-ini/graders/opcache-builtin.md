---
type: regex
target: last_message
flags: is
pattern: 'zend_extension.{0,160}(warn|built[- ]?in|always|redundant|no longer|remove)|(warn|built[- ]?in|always (loaded|compiled|built|available)|no longer).{0,160}opcache'
weight: 2
---
