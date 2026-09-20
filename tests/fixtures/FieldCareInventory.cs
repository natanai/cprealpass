// Minimal typed native boundaries; not an engine emulator.
public class ItemID {
    public string id;
    public static ItemID CreateQuery(string id) { return new ItemID { id = id }; }
}
public partial class PlayerPuppet {
    public GameInstance game = new GameInstance();
    public GameInstance GetGame() { return game; }
}
public partial class GameInstance {
    public TransactionSystem inventory = new TransactionSystem();
    public static TransactionSystem GetTransactionSystem(GameInstance game) { return game.inventory; }
}
public class TransactionSystem {
    public int count = 3;
    public bool removeFails;
    public bool giveFails;
    public int removeCalls;
    public int giveCalls;
    public string lastItem;
    public System.Action onRemove;
    private static bool IsFieldSupply(ItemID item) {
        return item != null && (item.id == "Items.GenericJunkItem4" || item.id == "Items.CommonMaterial1");
    }
    public int GetItemQuantity(PlayerPuppet player, ItemID item) {
        if (!IsFieldSupply(item)) throw new System.Exception("Wrong supply record");
        lastItem = item.id;
        return count;
    }
    public bool RemoveItem(PlayerPuppet player, ItemID item, int quantity) {
        removeCalls++;
        if (quantity != 1 || !IsFieldSupply(item)) throw new System.Exception("Wrong debit");
        lastItem = item.id;
        if (removeFails || count < quantity) return false;
        count -= quantity;
        var callback = onRemove;
        onRemove = null;
        callback?.Invoke();
        return true;
    }
    public bool GiveItem(PlayerPuppet player, ItemID item, int quantity) {
        giveCalls++;
        if (quantity != 1 || !IsFieldSupply(item)) throw new System.Exception("Wrong compensation");
        lastItem = item.id;
        if (giveFails) return false;
        count += quantity;
        return true;
    }
}
public static class CRBiologySessionAuthority {
    public static CRFieldCareActionRuntime FieldCare(GameInstance game) { return CRFieldCareActionRuntime.Get(); }
}
public static class CareCallbackFixture {
    public static int nestedResult = -1;
    public static void ChangeBody(PlayerPuppet player, CRInjuryState state) {
        player.game.inventory.onRemove = () => CRInjuryModel.Wound(state, 1, 0.1f, 0, 0, 10, 0);
    }
    public static void Reenter(PlayerPuppet player, CRFieldCarePlan plan, CRInjuryState state) {
        player.game.inventory.onRemove = () => nestedResult = CRFieldCareInventory.Execute(player, plan, state);
    }
}
