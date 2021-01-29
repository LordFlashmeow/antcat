# frozen_string_literal: true

# TODO: Add section for relational history items.

module DatabaseScripts
  module Tagging
    SECTIONS = [
      UNGROUPED_SECTION = "ungrouped",
      MAIN_SECTION = "main",
      MISSING_TAGS_SECTION = "missing-tags",
      CONVERT_TAX_TO_PROTT_TAGS_SECTION = "convert-tax-to-prott-tags",
      DISAGREEING_HISTORY_SECTION = "disagreeing-history",
      CODE_CHANGES_REQUIRED_SECTION = "code-changes-required",
      PENDING_AUTOMATION_ACTION_REQUIRED_SECTION = "pa-action-required",
      PENDING_AUTOMATION_NO_ACTION_REQUIRED_SECTION = "pa-no-action-required",
      LONG_RUNNING_SECTION = "long-running",
      NOT_NECESSARILY_INCORRECT_SECTION = "not-necessarily-incorrect",
      REVERSED_SECTION = "reversed",
      REGRESSION_TEST_SECTION = "regression-test",
      ORPHANED_RECORDS_SECTION = "orphaned-records",
      LIST_SECTION = "list",
      RESEARCH_SECTION = "research"
    ]
    SECTIONS_SORT_ORDER = SECTIONS
    TAGS = [
      SLOW_TAG = "slow",
      VERY_SLOW_TAG = "very-slow",
      SLOW_RENDER_TAG = "slow-render",
      NEW_TAG = "new!",
      UPDATED_TAG = "updated!",
      HAS_QUICK_FIX_TAG = "has-quick-fix",
      HIGH_PRIORITY_TAG = "high-priority",
      CODE_CHANGES_REQUIRED_SECTION,
      REGRESSION_TEST_SECTION,
      LIST_SECTION,
      "has-reversed"
    ]
  end
end
