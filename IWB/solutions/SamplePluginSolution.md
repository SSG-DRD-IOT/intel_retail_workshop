# Code for sample plugin
## AttendeeAnalyticsPlugin.cs

```c
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Intel.CFC.Plugin;


namespace AttendeeAnalyticsPlugin
{
    public class AttendeeAnalyticsPlugin : CFCPlugin
    {
        PluginUI UI = null;
        PluginInfo pluginDetails = new PluginInfo();
        PluginUIElementGroup uiElementGroup = new PluginUIElementGroup();
        string HubText = "";
        const string RAISEHAND = "00000000-0000-0000-0000-000000000009";
        //TODO : Declare attributes for advanced plugin
        public void SimpleTestPlugin()
        {
            pluginDetails.Name = "";
            pluginDetails.Id = new Guid("12345678-1234-1234-1234-123456781235");
            pluginDetails.Description = "Attendee Analytics";

            UI = new PluginUI();
            UI.pluginInfo = pluginDetails;
            UI.Groups = new List<PluginUIElementGroup>();
            uiElementGroup.GroupName = "Attendee Analytics";
            uiElementGroup.ImageBytes = ResourceToBytes(new Uri("/AttendeeAnalyticsPlugin;component/anlytics.png", System.UriKind.Relative));
            uiElementGroup.UIElements = new List<PluginUIElement>();
            uiElementGroup.Description = "";
            uiElementGroup.UIElements.Add(new PluginUIElement(new Guid(RAISEHAND), UIElementType.Button, "Raise Hand", "", ResourceToBytes(new Uri("/AttendeeAnalytics;component/raisehand.png", System.UriKind.Relative))));
            //TODO: Add UI elements for advanced plugin
            UI.Groups.Add(uiElementGroup);
        }
        public override void Load()
        {
            LogMessage("Plugin Loaded", null);
            SimpleTestPlugin();
        }

        public override void UnLoad()
        {
            LogMessage("Plugin Unloaded", null);
        }

        public override void UserConnected(UserEventArgs e)
        {
           //TODO: Implement Overridden method for Advanced plugin
            ShowHubToast(e.TargetUser.Name + " has joined!", new byte[0], 3);
            LogMessage("Plugin User Connect", null);

        }

        public override void UserDisconnected(UserEventArgs e)
        {
            //TODO: Implement Overridden method for Advanced plugin
            ShowHubToast(e.TargetUser.Name + " has disconnected!", new byte[0], 3);
            LogMessage("Plugin User Disconnect Loaded", null);

        }

        public override void UserPresentationStart(UserEventArgs e)
        {

            //TODO: Implement Overridden method for Advanced plugin
            LogMessage("Plugin Presentation Started", null);
            ShowHubToast("Presentation started by " + e.TargetUser.Name, new byte[0], 5);

        }

        public override void UserPresentationEnd(UserEventArgs e)
        {
            //TODO: Implement Overridden method for Advanced plugin
            LogMessage("Plugin Presentation End", null);
            ShowHubToast("Presentation ended by " + e.TargetUser.Name, new byte[0], 5);

        }

        public override void UIElementEvent(UIEventArgs e)
        {
            LogMessage("Plugin Received UI Event: " + e.ElementId.ToString(), null);
            byte[] currentStateImage = new byte[0];

            switch (e.ElementId.ToString())
            {

                case RAISEHAND:
                    currentStateImage = ResourceToBytes(new Uri("/AttendeeAnalyticsPlugin;component/raisehand.png", System.UriKind.Relative));
                    HubText = "User '" + e.TargetUser.Name.ToUpper() + "'" + " raised hand for a query";
                    ShowHubToast(HubText, currentStateImage, 5);
                    break;
                    //TODO: Handling more events

            }
            FireHubTextUpdated();
            FireUIUpdated();
        }

        public override PluginUI GetUI(UserEventArgs e)
        {
            return UI;
        }

        public override PluginInfo GetPluginInfo()
        {
            return pluginDetails;
        }

        public override string GetHubText()
        {
            return HubText;
        }

        //TODO: fetch Intel Unite application data

    }
}

```
