const MENU_ID = "fuyi-translate-selection";

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: MENU_ID,
    title: "用 ENJIMO Translate 翻译“%s”",
    contexts: ["selection"]
  });
});

async function sendToTab(tabId, message) {
  if (!tabId) return;
  try {
    await chrome.tabs.sendMessage(tabId, message);
  } catch {
    // Chrome 内部页面和应用商店不允许扩展注入脚本。
  }
}

chrome.action.onClicked.addListener((tab) => {
  sendToTab(tab.id, { type: "FUYI_TOGGLE" });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId !== MENU_ID) return;
  sendToTab(tab?.id, {
    type: "FUYI_SHOW",
    text: info.selectionText || "",
    autoTranslate: true
  });
});
