trigger DefaultEntitlement on Case (Before Insert) {
     Set<Id> accountIds = new Set<Id>();

    for (Case c : Trigger.new) {
        accountIds.add(c.AccountId);
    }

    accountIds.remove(null);

    if (!accountIds.isEmpty()) {
        Map<Id, Entitlement> entitlementMap = new Map<Id, Entitlement>();

        for (Entitlement e : [
            select AccountId,
                Name
            from Entitlement
            where AccountId in :accountIds
        ]) {
            entitlementMap.put(e.AccountId, e);
        }

        Entitlement process = [
            select Name
            from Entitlement
            where Name = 'Support'
        ];

        List<Entitlement> entitlementsToInsert = new List<Entitlement>();
        for (Id id : accountIds) {
            if (entitlementMap.containsKey(id)) {
                continue;
            }

            entitlementsToInsert.add(new Entitlement(
                Name = 'Support',
                SlaProcessId = process.Id,
                StartDate = Date.today().addDays(-1), // Start date of yesterday
                Enddate = Date.today().addDays(1), // End date of tomorrow
                AccountId = id
            ));
        }

        if (!entitlementsToInsert.isEmpty()) {
            insert entitlementsToInsert;

            for (Entitlement e : entitlementsToInsert) {
                entitlementMap.put(e.AccountId, e);
            }
        }

        for (Case c : Trigger.new) {
            if (c.AccountId == null) {
                continue;
            }

            c.EntitlementId = entitlementMap.get(c.AccountId).Id;
        }
    }
}