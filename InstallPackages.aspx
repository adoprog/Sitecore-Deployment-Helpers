<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore.Data.Engines" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.Update" %>
<%@ Import Namespace="Sitecore.Update.Metadata" %>
<%@ Import Namespace="Sitecore.Update.Installer" %>
<%@ Import Namespace="Sitecore.Update.Installer.Exceptions" %>
<%@ Import Namespace="Sitecore.Update.Installer.Installer.Utils" %>
<%@ Import Namespace="Sitecore.Update.Installer.Utils" %>
<%@ Import Namespace="Sitecore.Update.Utils" %>
<%@ Import Namespace="Sitecore.Update.Wizard" %>
<%@ Language=C# %>
<HTML>
   <script runat="server" language="C#">
    public void Page_Load(object sender, EventArgs e)
    {
      var files = Directory.GetFiles(Server.MapPath("/sitecore/admin/Packages"), "*.update", SearchOption.AllDirectories);
      Sitecore.Context.SetActiveSite("shell");
      using (new SecurityDisabler())
      {
        using (new ProxyDisabler())
        {
          using (new SyncOperationContext())
          {
            foreach (var file in files)
            {
              Install(file);
              Response.Write("Installed Package: " + file + "<br>");
            }
          }
        }
      }
    }

    protected static string Install(string package)
    {
      var logger = LogManager.GetLogger("LogFileAppender");
      string result;
      using (new ShutdownGuard())
      {
        var installationInfo = new PackageInstallationInfo
        {
          Action = UpgradeAction.Upgrade,
          Mode = InstallMode.Install,
          Path = package
        };
        string historyPath = null;
        List<ContingencyEntry> entries = null;
        try
        {
          entries = UpdateHelper.Install(installationInfo, logger, out historyPath);
          string error = string.Empty;
          logger.Info("Executing post installation actions.");
          MetadataView metadata = PreviewMetadataWizardPage.GetMetadata(package, out error);

          if (string.IsNullOrEmpty(error))
          {
              DiffInstaller diffInstaller = new DiffInstaller(UpgradeAction.Upgrade);
              using (new SecurityDisabler())
              {
                  diffInstaller.ExecutePostInstallationInstructions(package, historyPath, installationInfo.Mode, metadata, logger, ref entries);
              }
          }
          else
          {
              logger.Info("Post installation actions error.");
              logger.Error(error);
              throw new Exception(string.Format("Post installation actions error: {0}", error));
          }
        }
        catch (PostStepInstallerException ex)
        {
          entries = ex.Entries;
          historyPath = ex.HistoryPath;
          throw;
        }

        result = historyPath;
      }

      return result;
    }
    
    protected String GetTime()
    {
        return DateTime.Now.ToString("t");
    }
   </script>
   <body>
      <form id="MyForm" runat="server">
	<div>This page installs packages from \sitecore\admin\Packages folder.</div>
	Current server time is <% =GetTime()%>
      </form>
   </body>
</HTML>