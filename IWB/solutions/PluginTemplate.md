# Plugin Template

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
      //TODO : Declaring variables for plugin UI
      //TODO : Declaring variables for advanced plugin
      public void SimpleToastPlugin()
        {
           //TODO : Defining plugin properties
           //TODO : Adding UI elements      
        }
        public override void Load()
        {
            LogMessage("Plugin Loaded", null);
            SimpleToastPlugin();
        }

        public override void UnLoad()
        {
            LogMessage("Plugin Unloaded", null);
        }

        public override void UserConnected(UserEventArgs e)
        {
            //TODO: Implementing Overridden method for Advanced plugin
            ShowHubToast(e.TargetUser.Name + " has joined!", new byte[0], 3);
            LogMessage("Plugin User Connect", null);

        }

        public override void UserDisconnected(UserEventArgs e)
        {
            //TODO: Implementing Overridden method for Advanced plugin
            ShowHubToast(e.TargetUser.Name + " has disconnected!", new byte[0], 3);
            LogMessage("Plugin User Disconnect Loaded", null);

        }

        public override void UserPresentationStart(UserEventArgs e)
        {
            //TODO: Implementing Overridden method for Advanced plugin
            LogMessage("Plugin Presentation Started", null);

        }

        public override void UserPresentationEnd(UserEventArgs e)
        {
            //TODO: Implementing Overridden method for Advanced plugin
            LogMessage("Plugin Presentation End", null);
            ShowHubToast("Presentation ended by " + e.TargetUser.Name, new byte[0], 5);

        }

        public override void UIElementEvent(UIEventArgs e)
        {
            //TODO: Handling User event on plugin
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
