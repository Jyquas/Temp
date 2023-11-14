function Find-TermById {
    param (
        [Parameter(Mandatory = $true)]
        $Terms,
        [Parameter(Mandatory = $true)]
        $TermId
    )

    foreach ($term in $Terms) {
        if ($term.Id -eq $TermId) {
            return $term
        }

        if ($term.ChildTerms) {
            $foundTerm = Find-TermById -Terms $term.ChildTerms -TermId $TermId
            if ($foundTerm) {
                return $foundTerm
            }
        }
    }

    return $null
}
