browser.action.onClicked.addListener(async (tab) => {
    const url = tab.url || "";

    if (!url.match(/^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\//)) {
        browser.action.setBadgeText({ text: "!", tabId: tab.id });
        browser.action.setBadgeBackgroundColor({ color: "#FF6B6B", tabId: tab.id });
        setTimeout(() => {
            browser.action.setBadgeText({ text: "", tabId: tab.id });
        }, 2000);
        return;
    }

    try {
        const response = await browser.runtime.sendNativeMessage(
            "application.id",
            { url: url }
        );

        if (response && response.status === "ok") {
            browser.action.setBadgeText({ text: "✓", tabId: tab.id });
            browser.action.setBadgeBackgroundColor({ color: "#4CAF50", tabId: tab.id });
        } else {
            browser.action.setBadgeText({ text: "✗", tabId: tab.id });
            browser.action.setBadgeBackgroundColor({ color: "#FF6B6B", tabId: tab.id });
        }
    } catch (error) {
        console.error("Failed to send native message:", error);
        browser.action.setBadgeText({ text: "✗", tabId: tab.id });
        browser.action.setBadgeBackgroundColor({ color: "#FF6B6B", tabId: tab.id });
    }

    setTimeout(() => {
        browser.action.setBadgeText({ text: "", tabId: tab.id });
    }, 2000);
});
