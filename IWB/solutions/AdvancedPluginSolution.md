# Code for Advanced Plugin


***Note:*** For external Python* widget solution, click [here](./WidgetSolution.md)
## AttendeeAnalyticsPlugin.cs
```c
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Intel.CFC.Plugin;
using System.Diagnostics;


namespace AttendeeAnalyticsPlugin
{
    public class AttendeeAnalyticsPlugin : CFCPlugin
    {
        PluginUI UI = null;
        PluginInfo pluginDetails = new PluginInfo();
        PluginUIElementGroup uiElementGroup = new PluginUIElementGroup();
        string HubText = "";
        const string RAISEHAND = "00000000-0000-0000-0000-000000000008";
        const string LAUNCHAPP = "00000000-0000-0000-0000-000000000009";
        const string CLOSEAPP = "00000000-0000-0000-0000-000000000010";
        String str = null;
        String filepath = @"C:\\Users\\intel\\Desktop\\Retail\\OpenVINO\\UniteData.json";
        Process p = null;

        public void SimpleToastPlugin()
        {
            pluginDetails.Name = "";
            pluginDetails.Id = new Guid("12345678-1234-1234-1234-123456781235");
            pluginDetails.Description = "Attendee Analytics";

            UI = new PluginUI();
            UI.pluginInfo = pluginDetails;
            UI.Groups = new List<PluginUIElementGroup>();
            uiElementGroup.GroupName = "Attendee Analytics";
            uiElementGroup.ImageBytes = ResourceToBytes(new Uri("/AttendeeAnalyticsPlugin;component/Analytics_graph.png", System.UriKind.Relative));
            uiElementGroup.UIElements = new List<PluginUIElement>();
            uiElementGroup.Description = "";
            uiElementGroup.UIElements.Add(new PluginUIElement(new Guid(RAISEHAND), UIElementType.Button, "Raise Hand", "", ResourceToBytes(new Uri("/AttendeeAnalyticsPlugin;component/raisehand.png", System.UriKind.Relative))));
            uiElementGroup.UIElements.Add(new PluginUIElement(new Guid(LAUNCHAPP), UIElementType.Button, "Launch Analytics", "", ResourceToBytes(new Uri("/AttendeeAnalyticsPlugin;component/launch.png", System.UriKind.Relative))));
            uiElementGroup.UIElements.Add(new PluginUIElement(new Guid(CLOSEAPP), UIElementType.Button, "Close Analytics", "", ResourceToBytes(new Uri("/AttendeeAnalyticsPlugin;component/close.png", System.UriKind.Relative))));
            UI.Groups.Add(uiElementGroup);
        }

        public override void Load()
        {
            LogMessage("Plugin Loaded", null);
            SimpleToastPlugin();
        }

        public override void UserPresentationStart(UserEventArgs e)
        {
            str = "{\"usersConnected\":" + e.CurrentUsers.Count + ",\n\"usersPresenting\":" + GetNoOfPresenters(e) + ",\n\"timestamp\":\"" + DateTime.Now.ToString("h:mm:ss") + "\"}";
            System.IO.File.WriteAllText(filepath, str);
            LogMessage("Plugin Presentation Started", null);
            ShowHubToast("Presentation started by " + e.TargetUser.Name, new byte[0], 5);

        }

        public override void UIElementEvent(UIEventArgs e)
        {
            LogMessage("Plugin Received UI Event: " + e.ElementId.ToString(), null);
            byte[] currentStateImage = new byte[0];

            switch (e.ElementId.ToString())
            {
                case LAUNCHAPP:
                    if (this.p != null)
                    {
                        HubText = "User '" + e.TargetUser.Name.ToUpper() + "'" + " App already running";
                        ShowHubToast(HubText, currentStateImage, 5);
                    }
                    else
                    {
                        this.p = Process.Start("C:\\Users\\intel\\Desktop\\Retail\\"Intel Unite"\\Widget.pyw");
                    }
                    break;
                case RAISEHAND:
                    currentStateImage = ResourceToBytes(new Uri("/AttendeeAnalyticsPlugin;component/raisehand.png", System.UriKind.Relative));
                    HubText = "User '" + e.TargetUser.Name.ToUpper() + "'" + " raised hand for a query";
                    ShowHubToast(HubText, currentStateImage, 5);
                    break;

                case CLOSEAPP:
                    if (this.p != null)
                    {
                        this.p.Kill();
                        this.p = null;
                    }
                    else
                    {
                        HubText = "User '" + e.TargetUser.Name.ToUpper() + "':" + " The App is not running";
                        ShowHubToast(HubText, currentStateImage, 5);
                        this.p = null;
                    }

                    break;
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

        public int GetNoOfPresenters(UserEventArgs e)
        {
            int i = 0;
            foreach (UserInfo user in e.CurrentUsers) // Loop through List with foreach
            {
                if (user.isPresenting)
                {
                    i++;
                }
            }

            return i;
        }

        public override void UserPresentationEnd(UserEventArgs e)
        {
            str = "{\"usersConnected\":" + e.CurrentUsers.Count + ",\n\"usersPresenting\":" + GetNoOfPresenters(e) + ",\n\"timestamp\":\"" + DateTime.Now.ToString("h:mm:ss") + "\"}";
            System.IO.File.WriteAllText(filepath, str);
            LogMessage("Plugin Presentation End", null);
            ShowHubToast("Presentation ended by " + e.TargetUser.Name, new byte[0], 5);

        }

        public override void UserConnected(UserEventArgs e)
        {
            str = "{\"usersConnected\":" + e.CurrentUsers.Count + ",\n\"usersPresenting\":" + GetNoOfPresenters(e) + ",\n\"timestamp\":\"" + DateTime.Now.ToString("h:mm:ss") + "\"}";
            System.IO.File.WriteAllText(filepath, str);
            ShowHubToast(e.TargetUser.Name + " has joined!", new byte[0], 3);
            LogMessage("Plugin User Connect", null);

        }

        public override void UserDisconnected(UserEventArgs e)
        {
            str = "{\"usersConnected\":" + e.CurrentUsers.Count + ",\n\"usersPresenting\":" + GetNoOfPresenters(e) + ",\n\"timestamp\":\"" + DateTime.Now.ToString("h:mm:ss") + "\"}";
            System.IO.File.WriteAllText(filepath, str);
            ShowHubToast(e.TargetUser.Name + " has disconnected!", new byte[0], 3);
            LogMessage("Plugin User Disconnect Loaded", null);
        }

        public override void UnLoad()
        {
	   if (this.p != null)
           {
               this.p.Kill();
               this.p = null;
           }
           LogMessage("Plugin Unloaded", null);
        }        

    }
}
```
